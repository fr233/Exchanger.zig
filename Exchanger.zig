const std = @import("std");
const expect = std.testing.expect;

pub fn Exchanger(comptime T: type) type {
    return struct {
        pub const Node = struct {
            status: i32=1,
            item: T=undefined,
            resetEvent: std.ResetEvent,
        };
        const Self = @This();
        
        dst: ?*Node = null,
        
        pub fn init() Self {
            return Self{};
        }

        pub fn exchange(self: *Self, item: T) T {
            return self.doExchange(item, null).?;
        }

        pub fn timedExchange(self: *Self, item: T, timeout_ns: u64) ?T {
            return self.doExchange(item, timeout_ns);
        }

        fn doExchange(self: *Self, item: T, timeout_ns: ?u64) ?T {
            var node = Node{.item=item, .resetEvent = std.ResetEvent.init()};
            defer node.resetEvent.deinit();
            @fence(.Release);
            var pair = self.dst;
            while(true) {
                if(pair == null) {
                    var ret = @cmpxchgWeak(?*Node, &self.dst, null, &node, .Acquire, .Monotonic);
                    if(ret) |val| {
                        pair = val;
                        continue;
                    } else {
                        var r: anyerror!void = {};
                        if(timeout_ns) |timeout|{
                            r = node.resetEvent.timedWait(timeout);
                        } else {
                            node.resetEvent.wait();
                        }
                        const status = node.status;
                        
                        if(r) |_| {
                            if(status == 1) {
                                std.debug.print("unexpected wake up\n", .{});
                            }
                            expect(status == 0);
                            
                            return node.item;
                            
                        } else |err| {     // only timedExchange() could reach this branch
                            ret = @cmpxchgWeak(?*Node, &self.dst, &node, null, .Acquire, .Monotonic);
                            if(ret) |_| {      // cmpxchg failed, another thread is holding a reference to node and hasn't finished copying, wait it.
                                std.debug.print("wait copying, isSet()={}\n", .{node.resetEvent.isSet()});
                                node.resetEvent.wait();
                                expect(node.status == 0);
                                return node.item;
                            } else {
                                return null;
                            }
                        }
                    }
                } else {
                    var ret = @cmpxchgWeak(?*Node, &self.dst, pair, null, .Acquire, .Monotonic);
                    if(ret) |val| {
                        pair = val;
                        continue;
                    } else {
                        const p = pair.?;
                        var item_dst = p.item;
                        p.item = item;
                        p.status = 0;
                        p.resetEvent.set();
                        return item_dst;
                    }
                }
            }
        }
        
        
    };
}