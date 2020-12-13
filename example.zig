const std = @import("std");

const Exchanger = @import("./Exchanger.zig").Exchanger;


const U64Exchanger = Exchanger(u64);

const Param = struct {
    id: usize,
    exchanger: *U64Exchanger,
    total_thread:usize,
};

var result:[2]u32=undefined;


fn exchanger_test(param: Param) !void {
    var id = param.id;
    var ex = param.exchanger;

    
    var i:usize = id;
    while(i < 10000000000){
        
        var item:?u64 = null;
        
        item = ex.exchange(i);
        //item = ex.timedExchange(i, 100);

        if(i%1000000 <= param.total_thread+5){
            std.debug.print("thread: {}\tput:{:10}\t get:{:10}\n", .{id, i, item});
        }
        if(item != null){
            i+=param.total_thread;
        }
    }
}

var end:u32 = 0;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    
    end = 1;

    const thread_count = 6;

    var a:[thread_count]*std.Thread = undefined;

    var exchanger = U64Exchanger{};

    var param = Param{.id=0, .exchanger=&exchanger, .total_thread=thread_count};
    for(a[0..thread_count]) |*item|{
        item.* = std.Thread.spawn(param, exchanger_test) catch unreachable;
        param.id+=1;
    }
    
    std.time.sleep(10000000000);

    var start = std.time.milliTimestamp();
    for(a)|item, idx|{
        item.wait();
    }
    
    var count:u32 = 0;
    //for(result)|v|{
    //    count += v;
    //}

    std.debug.print("{}  {}\n", .{std.time.milliTimestamp() - start, count});

}