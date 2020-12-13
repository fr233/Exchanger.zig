# Exchanger.zig
a naive Exchanger for zig lang

# API
* `Exchanger(comptime T: type) type`
generic type

* `init() Self`
construct an Exchanger object

* `exchange(self: *Self, item: T) T`
Waits for another thread to arrive at this exchange point, and then transfers the given item to it, receiving its item in return

* `timedExchange(self: *Self, item: T, timeout_ns: u64) ?T`
same as exchange(), but return null if timed out.

