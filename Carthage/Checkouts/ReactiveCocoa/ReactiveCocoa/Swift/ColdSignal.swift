//
//  ColdSignal.swift
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2014-06-25.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

import LlamaKit

func doNothing<T>(value: T) {}
func doNothing(error: NSError) {}
func doNothing() {}

/// Represents a stream event.
///
/// Streams must conform to the grammar:
/// `Next* (Error | Completed)?`
public enum Event<T> {
	/// A value provided by the stream.
	case Next(Box<T>)

	/// The stream terminated because of an error.
	case Error(NSError)

	/// The stream successfully terminated.
	case Completed

	/// Whether this event indicates stream termination (from success or
	/// failure).
	public var isTerminating: Bool {
		switch self {
		case let .Next:
			return false

		default:
			return true
		}
	}

	/// Lifts the given function over the event's value.
	public func map<U>(f: T -> U) -> Event<U> {
		switch self {
		case let .Next(box):
			return .Next(Box(f(box.unbox)))

		case let .Error(error):
			return .Error(error)

		case let .Completed:
			return .Completed
		}
	}

	/// Case analysis on the receiver.
	public func event<U>(#ifNext: T -> U, ifError: NSError -> U, ifCompleted: @autoclosure () -> U) -> U {
		switch self {
		case let .Next(box):
			return ifNext(box.unbox)

		case let .Error(err):
			return ifError(err)

		case let .Completed:
			return ifCompleted()
		}
	}
}

/// A stream that will begin generating Events when a sink is attached, possibly
/// performing some side effects in the process. Events are pushed to the sink
/// as they are generated.
///
/// A corollary to this is that different sinks may see a different timing of
/// Events, or even a different version of events altogether.
public struct ColdSignal<T> {
	/// The type of value that will be sent to any sink which attaches to this
	/// signal.
	public typealias Element = Event<T>

	/// A closure which implements the behavior for a ColdSignal.
	public typealias Generator = (SinkOf<Element>, CompositeDisposable) -> ()

	private let generator: Generator

	/// Initializes a signal that will run the given action whenever a
	/// subscription is created.
	public init(generator: Generator) {
		self.generator = generator
	}

	/// Runs the given closure with a new disposable, then starts producing
	/// events for the returned sink, performing any side effects embedded
	/// within the ColdSignal.
	///
	/// The disposable given to the closure will cancel the work associated with
	/// event production, and prevent any further events from being sent.
	///
	/// Returns the disposable which was given to the closure.
	public func startWithSink(sinkCreator: Disposable -> SinkOf<Element>) -> Disposable {
		let disposable = CompositeDisposable()
		var innerSink: SinkOf<Element>? = sinkCreator(disposable)

		// Skip all generation work if the disposable was already used.
		if disposable.disposed {
			return disposable
		}

		let queue = dispatch_queue_create("org.reactivecocoa.ReactiveCocoa.ColdSignal.startWithSink", DISPATCH_QUEUE_SERIAL)
		disposable.addDisposable {
			// This is redundant with the behavior of the outer sink below for a
			// terminating event, but this ensures that we properly handle
			// simple cancellation as well.
			dispatch_async(queue) {
				innerSink = nil
			}
		}

		let outerSink = SinkOf<Element> { event in
			dispatch_sync(queue) {
				if disposable.disposed {
					return
				}

				if event.isTerminating {
					disposable.dispose()
				}

				// This variable should only be nil after disposal (which occurs
				// upon our current queue), so there's no situation in which
				// this should be nil here.
				innerSink!.put(event)
			}
		}

		generator(outerSink, disposable)
		return disposable
	}

	/// Starts producing events, performing any side effects embedded within the
	/// ColdSignal, and invoking the given handlers for each kind of event
	/// generated.
	///
	/// Returns a disposable that will cancel the work associated with event
	/// production, and prevent any further events from being sent.
	public func start(next: T -> () = doNothing, error: NSError -> () = doNothing, completed: () -> () = doNothing) -> Disposable {
		return startWithSink { _ in eventSink(next: next, error: error, completed: completed) }
	}
}

/// Convenience constructors.
extension ColdSignal {
	/// Creates a signal that will execute the given action upon subscription,
	/// then forward all events from the generated signal.
	public static func lazy(action: () -> ColdSignal) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			if !disposable.disposed {
				action().startWithSink { innerDisposable in
					disposable.addDisposable(innerDisposable)
					return sink
				}
			}
		}
	}

	/// Creates a signal that will immediately complete.
	public static func empty() -> ColdSignal {
		return ColdSignal { (sink, _) in
			sink.put(.Completed)
		}
	}

	/// Creates a signal that will immediately yield a single value then
	/// complete.
	public static func single(value: T) -> ColdSignal {
		return ColdSignal { (sink, _) in
			sink.put(.Next(Box(value)))
			sink.put(.Completed)
		}
	}

	/// Creates a signal that will immediately generate an error.
	public static func error(error: NSError) -> ColdSignal {
		return ColdSignal { (sink, _) in
			sink.put(.Error(error))
		}
	}

	/// Creates a signal that will never send any events.
	public static func never() -> ColdSignal {
		return ColdSignal { _ in () }
	}

	/// Creates a signal that will iterate over the given sequence whenever a
	/// sink is attached.
	///
	/// If the signal will be consumed multiple times, the given sequence must
	/// be multi-pass (i.e., support obtaining and using multiple generators).
	public static func fromValues<S: SequenceType where S.Generator.Element == T>(values: S) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			var generator = values.generate()

			while let value: T = generator.next() {
				sink.put(.Next(Box(value)))

				if disposable.disposed {
					return
				}
			}

			sink.put(.Completed)
		}
	}

	/// Creates a signal that will yield events equivalent to the given Result.
	///
	/// Returns a signal that will send one value then complete, or error.
	public static func fromResult(result: Result<T>) -> ColdSignal {
		switch result {
		case let .Success(value):
			return .single(value.unbox)

		case let .Failure(error):
			return .error(error)
		}
	}
}

/// Transformative operators.
extension ColdSignal {
	/// Maps over the elements of the signal, accumulating a state along the
	/// way.
	///
	/// This is meant as a primitive operator from which more complex operators
	/// can be built.
	///
	/// Yielding a `nil` state at any point will stop evaluation of the original
	/// signal, and dispose of it.
	///
	/// Returns a signal of the mapped values.
	public func mapAccumulate<State, U>(#initialState: State, _ f: (State, T) -> (State?, U)) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			let state = Atomic(initialState)

			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { value in
					let (maybeState, newValue) = f(state.value, value)
					sink.put(.Next(Box(newValue)))

					if let s = maybeState {
						state.value = s
					} else {
						sink.put(.Completed)
					}
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					sink.put(.Completed)
				})
			}

			return ()
		}
	}

	/// Maps each value in the stream to a new value.
	public func map<U>(f: T -> U) -> ColdSignal<U> {
		return mapAccumulate(initialState: ()) { (_, value) in
			return ((), f(value))
		}
	}

	/// Preserves only the values of the signal that pass the given predicate.
	public func filter(predicate: T -> Bool) -> ColdSignal {
		return self
			.map { value -> ColdSignal in
				if predicate(value) {
					return .single(value)
				} else {
					return .empty()
				}
			}
			.merge(identity)
	}

	/// Combines all the values in the stream, forwarding the result of each
	/// intermediate combination step.
	public func scan<U>(#initial: U, _ f: (U, T) -> U) -> ColdSignal<U> {
		return mapAccumulate(initialState: initial) { (previous, current) in
			let mapped = f(previous, current)
			return (mapped, mapped)
		}
	}

	/// Combines all of the values in the stream.
	///
	/// Returns a signal which will send the single, aggregated value when
	/// the receiver completes.
	public func reduce<U>(#initial: U, _ f: (U, T) -> U) -> ColdSignal<U> {
		let scanned = scan(initial: initial, f)

		return ColdSignal<U>.single(initial)
			.concat(scanned)
			.takeLast(1)
	}

	/// Combines each value from the signal with its preceding value, starting
	/// with `initialValue`.
	public func combinePrevious(#initial: T) -> ColdSignal<(T, T)> {
		return mapAccumulate(initialState: initial) { (previous, current) in
			return (current, (previous, current))
		}
	}

	/// Returns a signal that will skip the first `count` values from the
	/// receiver, then forward everything afterward.
	public func skip(count: Int) -> ColdSignal {
		precondition(count >= 0)

		if (count == 0) {
			return self
		}

		return self
			.mapAccumulate(initialState: 0) { (n, value) in
				if n >= count {
					return (count, .single(value))
				} else {
					return (n + 1, .empty())
				}
			}
			.merge(identity)
	}

	/// Skips all consecutive, repeating values in the signal, forwarding only
	/// the first occurrence.
	///
	/// evidence - Used to prove to the typechecker that the receiver contains
	///            values which are `Equatable`. Simply pass in the `identity`
	///            function.
	public func skipRepeats<U: Equatable>(evidence: ColdSignal -> ColdSignal<U>) -> ColdSignal<U> {
		return evidence(self).skipRepeats { $0 == $1 }
	}

	/// Skips all consecutive, repeating values in the signal, forwarding only
	/// the first occurrence.
	///
	/// isEqual - Used to determine whether two values are equal. The `==`
	///           function will work in most cases.
	public func skipRepeats(isEqual: (T, T) -> Bool) -> ColdSignal<T> {
		return mapAccumulate(initialState: nil) { (maybePrevious: T?, current: T) -> (T??, ColdSignal<T>) in
				if let previous = maybePrevious {
					if isEqual(current, previous) {
						return (current, .empty())
					}
				}

				return (current, .single(current))
			}
			.merge(identity)
	}

	/// Returns a signal that will skip values from the receiver while `pred`
	/// remains `true`, then forward everything afterward.
	public func skipWhile(predicate: T -> Bool) -> ColdSignal {
		return self
			.mapAccumulate(initialState: true) { (skipping, value) in
				if !skipping || !predicate(value) {
					return (false, .single(value))
				} else {
					return (true, .empty())
				}
			}
			.merge(identity)
	}

	/// Returns a signal that will yield the first `count` values from the
	/// receiver.
	public func take(count: Int) -> ColdSignal {
		precondition(count >= 0)

		if count == 0 {
			return .empty()
		}

		return mapAccumulate(initialState: 0) { (n, value) in
			let newN: Int? = (n + 1 < count ? n + 1 : nil)
			return (newN, value)
		}
	}

	/// Waits for the receiver to complete successfully, then forwards only the
	/// last `count` values.
	public func takeLast(count: Int) -> ColdSignal {
		precondition(count >= 0)

		if count == 0 {
			return filter { _ in false }
		}

		return ColdSignal { (sink, disposable) in
			let values: Atomic<[T]> = Atomic([])

			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { value in
					values.modify { (var arr) in
						arr.append(value)
						while arr.count > count {
							arr.removeAtIndex(0)
						}

						return arr
					}

					return ()
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					for v in values.value {
						sink.put(.Next(Box(v)))
					}

					sink.put(.Completed)
				})
			}
		}
	}

	/// Forwards all events from the receiver, until `trigger` fires, at which
	/// point the returned signal will complete.
	public func takeUntil(trigger: HotSignal<()>) -> ColdSignal {
		let disposable = CompositeDisposable()
		let triggerDisposable = trigger.observe { _ in
			disposable.dispose()
		}

		disposable.addDisposable(triggerDisposable)

		return ColdSignal { (sink, sinkDisposable) in
			// Automatically complete the returned signal when the trigger
			// fires.
			let completingDisposable = ActionDisposable {
				sink.put(.Completed)
			}

			disposable.addDisposable(completingDisposable)

			self.startWithSink { selfDisposable in
				sinkDisposable.addDisposable {
					selfDisposable.dispose()

					// When this subscription terminates, make sure to prune our
					// unique disposable from `disposable`, to avoid infinite
					// memory growth.
					completingDisposable.dispose()
					disposable.pruneDisposed()
				}

				return sink
			}
		}
	}

	/// Returns a signal that will yield values from the receiver while
	/// `predicate` remains `true`.
	public func takeWhile(predicate: T -> Bool) -> ColdSignal {
		return self
			.mapAccumulate(initialState: true) { (taking, value) in
				if taking && predicate(value) {
					return (true, .single(value))
				} else {
					return (nil, .empty())
				}
			}
			.merge(identity)
	}

	/// Yields all events on the given scheduler, instead of whichever
	/// scheduler they originally arrived upon.
	public func deliverOn(scheduler: Scheduler) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return SinkOf { event in
					scheduler.schedule { sink.put(event) }
					return ()
				}
			}

			return ()
		}
	}

	/// Performs the work of event production on the given Scheduler.
	///
	/// This implies that any side effects embedded in the receiver will be
	/// performed on the given scheduler as well.
	///
	/// Values may still be sent upon other schedulers—this merely affects how
	/// the `start` method is invoked.
	public func subscribeOn(scheduler: Scheduler) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			let schedulerDisposable = scheduler.schedule {
				self.startWithSink { selfDisposable in
					disposable.addDisposable(selfDisposable)
					return sink
				}

				return ()
			}

			disposable.addDisposable(schedulerDisposable)
		}
	}

	/// Delays `Next` and `Completed` events by the given interval, forwarding
	/// them on the given scheduler.
	///
	/// `Error` events are always scheduled immediately.
	public func delay(interval: NSTimeInterval, onScheduler scheduler: DateScheduler) -> ColdSignal {
		precondition(interval >= 0)

		return ColdSignal { (sink, disposable) in
			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return SinkOf { event in
					switch event {
					case .Error:
						scheduler.schedule {
							sink.put(event)
						}

					default:
						let date = scheduler.currentDate.dateByAddingTimeInterval(interval)
						scheduler.scheduleAfter(date) {
							sink.put(event)
						}
					}
				}
			}

			return ()
		}
	}

	/// Yields `error` after the given interval if the receiver has not yet
	/// completed by that point.
	public func timeoutWithError(error: NSError, afterInterval interval: NSTimeInterval, onScheduler scheduler: DateScheduler) -> ColdSignal {
		precondition(interval >= 0)

		return ColdSignal { (sink, disposable) in
			let date = scheduler.currentDate.dateByAddingTimeInterval(interval)
			let timeoutDisposable = scheduler.scheduleAfter(date) {
				sink.put(.Error(error))
			}

			disposable.addDisposable(timeoutDisposable)

			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)
				return sink
			}

			return ()
		}
	}

	/// Injects side effects to be performed upon the specified signal events.
	public func on(subscribed: () -> () = doNothing, next: T -> () = doNothing, error: NSError -> () = doNothing, completed: () -> () = doNothing, terminated: () -> () = doNothing, disposed: () -> () = doNothing) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			subscribed()
			disposable.addDisposable(disposed)

			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { value in
					next(value)
					sink.put(.Next(Box(value)))
				}, error: { err in
					error(err)
					terminated()
					sink.put(.Error(err))
				}, completed: {
					completed()
					terminated()
					sink.put(.Completed)
				})
			}

			return ()
		}
	}

	/// Performs the given action upon each value in the receiver, bailing out
	/// with an error if it returns `false`.
	public func try(f: (T, NSErrorPointer) -> Bool) -> ColdSignal {
		return tryMap { (value, error) in f(value, error) ? value : nil }
	}

	/// Attempts to map each value in the receiver, bailing out with an error if
	/// a given mapping is `nil`.
	public func tryMap<U>(f: (T, NSErrorPointer) -> U?) -> ColdSignal<U> {
		return tryMap { value -> Result<U> in
			var error: NSError?
			let maybeValue = f(value, &error)

			if let v = maybeValue {
				return .Success(Box(v))
			} else {
				return .Failure(error.orDefault(RACError.Empty.error))
			}
		}
	}

	/// Attempts to map each value in the receiver, bailing out with an error if
	/// a given mapping fails.
	public func tryMap<U>(f: T -> Result<U>) -> ColdSignal<U> {
		return self
			.map { value in
				switch f(value) {
				case let .Success(box):
					return .single(box.unbox)

				case let .Failure(error):
					return .error(error)
				}
			}
			.merge(identity)
	}

	/// Switches to a new signal when an error occurs.
	public func catch(handler: NSError -> ColdSignal) -> ColdSignal {
		return ColdSignal { (sink, disposable) in
			let serialDisposable = SerialDisposable()
			disposable.addDisposable(serialDisposable)

			self.startWithSink { selfDisposable in
				serialDisposable.innerDisposable = selfDisposable

				return SinkOf<Element> { event in
					switch event {
					case let .Error(error):
						handler(error).startWithSink { handlerDisposable in
							serialDisposable.innerDisposable = handlerDisposable
							return sink
						}

					default:
						sink.put(event)
					}
				}
			}
		}
	}

	/// Brings all signal Events into the monad, allowing them to be manipulated
	/// just like any other value.
	public func materialize() -> ColdSignal<Event<T>> {
		return ColdSignal<Event<T>> { (sink, disposable) in
			self.startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return SinkOf { event in
					sink.put(.Next(Box(event)))

					if event.isTerminating {
						sink.put(.Completed)
					}
				}
			}

			return ()
		}
	}

	/// The inverse of `materialize`, this will translate a signal of `Event`
	/// _values_ into a signal of those events themselves.
	///
	/// evidence - Used to prove to the typechecker that the receiver contains
	///            `Event`s. Simply pass in the `identity` function.
	public func dematerialize<U>(evidence: ColdSignal -> ColdSignal<Event<U>>) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			evidence(self).startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { event in
					sink.put(event)
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					sink.put(.Completed)
				})
			}

			return ()
		}
	}
}

/// Methods for combining multiple signals.
extension ColdSignal {
	private func startWithStates<U>(disposable: CompositeDisposable, _ selfState: CombineLatestState<T>, _ otherState: CombineLatestState<U>, queue: dispatch_queue_t, onBothNext: () -> (), onError: NSError -> (), onBothCompleted: () -> ()) {
		startWithSink { selfDisposable in
			disposable.addDisposable(selfDisposable)

			return eventSink(next: { value in
				dispatch_sync(queue) {
					selfState.latestValue = value
					if otherState.latestValue == nil {
						return
					}

					onBothNext()
				}
			}, error: onError, completed: {
				dispatch_sync(queue) {
					selfState.completed = true
					if otherState.completed {
						onBothCompleted()
					}
				}
			})
		}
	}

	/// Combines the latest value of the receiver with the latest value from
	/// the given signal.
	///
	/// The returned signal will not send a value until both inputs have sent
	/// at least one value each.
	public func combineLatestWith<U>(signal: ColdSignal<U>) -> ColdSignal<(T, U)> {
		return ColdSignal<(T, U)> { (sink, disposable) in
			let queue = dispatch_queue_create("org.reactivecocoa.ReactiveCocoa.ColdSignal.combineLatestWith", DISPATCH_QUEUE_SERIAL)
			let selfState = CombineLatestState<T>()
			let otherState = CombineLatestState<U>()

			let onBothNext = { () -> () in
				let combined = (selfState.latestValue!, otherState.latestValue!)
				sink.put(.Next(Box(combined)))
			}

			let onError = { sink.put(.Error($0)) }
			let onBothCompleted = { sink.put(.Completed) }

			self.startWithStates(disposable, selfState, otherState, queue: queue, onBothNext: onBothNext, onError: onError, onBothCompleted: onBothCompleted)
			signal.startWithStates(disposable, otherState, selfState, queue: queue, onBothNext: onBothNext, onError: onError, onBothCompleted: onBothCompleted)
		}
	}

	/// Merges a signal of signals down into a single signal, biased toward the
	/// signals added earlier.
	///
	/// evidence - Used to prove to the typechecker that the receiver is
	///            a signal of signals. Simply pass in the `identity` function.
	///
	/// Returns a signal that will forward events from the original signals
	/// as they arrive.
	public func merge<U>(evidence: ColdSignal -> ColdSignal<ColdSignal<U>>) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			let inFlight = Atomic(1)

			let decrementInFlight: () -> () = {
				let orig = inFlight.modify { $0 - 1 }
				if orig == 1 {
					sink.put(.Completed)
				}
			}

			evidence(self).startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { signal in
					signal.startWithSink { signalDisposable in
						inFlight.modify { $0 + 1 }
						disposable.addDisposable(signalDisposable)

						return SinkOf { event in
							if event.isTerminating {
								signalDisposable.dispose()
								disposable.pruneDisposed()
							}

							switch event {
							case .Completed:
								decrementInFlight()

							default:
								sink.put(event)
							}
						}
					}

					return ()
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					decrementInFlight()
				})
			}

			return ()
		}
	}

	/// Switches on a signal of signal, forwarding events from the
	/// latest inner signal.
	///
	/// evidence - Used to prove to the typechecker that the receiver is
	///            a signal of signals. Simply pass in the `identity` function.
	///
	/// Returns a signal that will forward events only from the latest
	/// signal sent upon the receiver.
	public func switchToLatest<U>(evidence: ColdSignal -> ColdSignal<ColdSignal<U>>) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			let selfCompleted = Atomic(false)
			let latestCompleted = Atomic(false)

			let completeIfNecessary: () -> () = {
				if selfCompleted.value && latestCompleted.value {
					sink.put(.Completed)
				}
			}

			let latestDisposable = SerialDisposable()
			disposable.addDisposable(latestDisposable)

			evidence(self).startWithSink { selfDisposable in
				latestDisposable.innerDisposable = selfDisposable

				return eventSink(next: { signal in
					latestDisposable.innerDisposable = signal.startWithSink { signalDisposable in
						latestDisposable.innerDisposable = signalDisposable

						return SinkOf { innerEvent in
							switch innerEvent {
							case .Completed:
								latestCompleted.value = true
								completeIfNecessary()

							default:
								sink.put(innerEvent)
							}
						}
					}
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					selfCompleted.value = true
					completeIfNecessary()
				})
			}
		}
	}

	/// Concatenates each inner signal with the previous and next inner signals.
	///
	/// evidence - Used to prove to the typechecker that the receiver is
	///            a signal of signals. Simply pass in the `identity` function.
	///
	/// Returns a signal that will forward events from each of the original
	/// signals, in sequential order.
	public func concat<U>(evidence: ColdSignal -> ColdSignal<ColdSignal<U>>) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			var state = ConcatState<U>(sink: sink, disposable: disposable)

			evidence(self).startWithSink { selfDisposable in
				disposable.addDisposable(selfDisposable)

				return eventSink(next: { signal in
					// TODO: Avoid multiple dispatches.
					dispatch_sync(state.queue) {
						state.enqueuedSignals.append(signal)
					}

					state.dequeueIfReady()
				}, error: { error in
					sink.put(.Error(error))
				}, completed: {
					state.decrementInFlight()
				})
			}
		}
	}

	/// Concatenates the given signal after the receiver.
	public func concat(signal: ColdSignal) -> ColdSignal {
		return ColdSignal<ColdSignal>.fromValues([ self, signal ])
			.concat(identity)
	}

	/// Ignores all values from the receiver, then subscribes to and forwards
	/// events from the given signal once the receiver has completed.
	public func then<U>(signal: ColdSignal<U>) -> ColdSignal<U> {
		return ColdSignal<U> { (sink, disposable) in
			let serialDisposable = SerialDisposable()
			disposable.addDisposable(serialDisposable)

			self.startWithSink { selfDisposable in
				serialDisposable.innerDisposable = selfDisposable

				return eventSink(error: { error in
					sink.put(.Error(error))
				}, completed: {
					signal.startWithSink { signalDisposable in
						serialDisposable.innerDisposable = signalDisposable
						return sink
					}

					return ()
				})
			}

			return ()
		}
	}
}

/// Blocking methods for receiving values.
extension ColdSignal {
	/// Subscribes to the receiver, then returns the first value received.
	public func first() -> Result<T> {
		let semaphore = dispatch_semaphore_create(0)
		var result: Result<T> = failure(RACError.ExpectedCountMismatch.error)

		take(1).start(next: { value in
			result = success(value)
			dispatch_semaphore_signal(semaphore)
		}, error: { error in
			result = failure(error)
			dispatch_semaphore_signal(semaphore)
		}, completed: {
			dispatch_semaphore_signal(semaphore)
			return ()
		})

		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
		return result
	}

	/// Subscribes to the receiver, then returns the last value received.
	public func last() -> Result<T> {
		return takeLast(1).first()
	}

	/// Subscribes to the receiver, and returns a successful result if exactly
	/// one value is received. If the receiver sends fewer or more values, an
	/// error will be returned instead.
	public func single() -> Result<T> {
		let result = reduce(initial: Array<T>()) { (var array, value) in
			array.append(value)
			return array
		}.first()

		switch result {
		case let .Success(values):
			if values.unbox.count == 1 {
				return success(values.unbox[0])
			} else {
				return failure(RACError.ExpectedCountMismatch.error)
			}

		case let .Failure(error):
			return failure(error)
		}
	}

	/// Subscribes to the receiver, then waits for completion.
	public func wait() -> Result<()> {
		return reduce(initial: ()) { (_, _) in () }
			.takeLast(1)
			.first()
	}
}

/// Conversions from ColdSignal to HotSignal.
extension ColdSignal {
	/// Immediately subscribes to the receiver, then forwards all values on the
	/// returned signal.
	///
	/// If `errorHandler` is `nil`, the stream must never produce an `Error`
	/// event.
	public func startMulticasted(#errorHandler: (NSError -> ())?, completionHandler: () -> () = doNothing) -> HotSignal<T> {
		return HotSignal { sink in
			var onError = { (error: NSError) in
				assert(false)
			}

			// Apparently ?? has trouble with closures, so use this lame pattern
			// instead.
			if let errorHandler = errorHandler {
				onError = errorHandler
			}

			return self.self.start(next: { value in
				sink.put(value)
			}, error: onError, completed: completionHandler)
		}
	}
}

/// Creates a sink that can receive events from a ColdSignal, then invoke the
/// given handlers based on the event type.
public func eventSink<T>(next: T -> () = doNothing, error: NSError -> () = doNothing, completed: () -> () = doNothing) -> SinkOf<Event<T>> {
	return SinkOf { event in
		switch event {
		case let .Next(value):
			next(value.unbox)

		case let .Error(err):
			error(err)

		case .Completed:
			completed()
		}
	}
}

private class CombineLatestState<T> {
	var latestValue: T?
	var completed = false
}

private class ConcatState<T> {
	let queue = dispatch_queue_create("org.reactivecocoa.ReactiveCocoa.ColdSignal.concat", DISPATCH_QUEUE_SERIAL)
	let sink: SinkOf<Event<T>>
	let disposable: CompositeDisposable

	var inFlight: Int = 1
	var enqueuedSignals = [ColdSignal<T>]()
	var currentSignal: ColdSignal<T>?

	init(sink: SinkOf<Event<T>>, disposable: CompositeDisposable) {
		self.sink = sink
		self.disposable = disposable
	}

	func decrementInFlight() {
		dispatch_sync(queue) {
			if --self.inFlight == 0 && self.enqueuedSignals.count == 0 && self.currentSignal == nil {
				self.sink.put(.Completed)
			}
		}
	}

	func dequeueIfReady() {
		var signal: ColdSignal<T>?

		dispatch_sync(queue) {
			if self.currentSignal != nil {
				return
			} else if self.enqueuedSignals.count == 0 {
				return
			}

			signal = self.enqueuedSignals.removeAtIndex(0)
			self.currentSignal = signal
			self.inFlight++
		}

		if let signal = signal {
			signal.startWithSink { signalDisposable in
				self.disposable.addDisposable(signalDisposable)

				return eventSink(next: { value in
					self.sink.put(.Next(Box(value)))
				}, error: { error in
					self.sink.put(.Error(error))

					// TODO: We should remove our disposable from the
					// composite disposable here, but that is non-trivial to
					// do right now. See https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1535.
				}, completed: {
					dispatch_sync(self.queue) {
						self.currentSignal = nil
					}

					// TODO: Avoid multiple dispatches.
					self.decrementInFlight()
					self.dequeueIfReady()
				})
			}
		}
	}
}
