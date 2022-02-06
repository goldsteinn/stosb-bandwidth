#! /usr/bin/env python3

import os

do_compile_fmt = "gcc {} -s -static -nostartfiles -nodefaultlibs -nostdlib -Wl,--build-id=none {}.S -o {}"

do_exec_fmt = "./{}"

do_perf = "perf stat  --all-user -e cycles"
perf_bandwidth_events = ",cpu/event=0x24,umask=0x27,name=l2_rqsts_all_demand_miss/,cpu/event=0x24,umask=0xe7,name=l2_rqsts_all_demand_references/,cpu/event=0x24,umask=0xe2,name=l2_rqsts_all_rfo/,cpu/event=0x24,umask=0xc2,name=l2_rqsts_rfo_hit/,cpu/event=0x24,umask=0x22,name=l2_rqsts_rfo_miss/,cpu/event=0xb0,umask=0x08,name=offcore_requests_all_data_rd/,cpu/event=0xb0,umask=0x80,name=offcore_requests_all_requests/,cpu/event=0xb0,umask=0x01,name=offcore_requests_demand_data_rd/,cpu/event=0xb0,umask=0x04,name=offcore_requests_demand_rfo/,cpu/event=0x60,umask=0x08,name=offcore_requests_outstanding_all_data_rd/,cpu/event=0x60,umask=0x01,name=offcore_requests_outstanding_demand_data_rd/,cpu/event=0x60,umask=0x04,name=offcore_requests_outstanding_demand_rfo/"


class Config():
    def __init__(self, executable, todo, vec_mov, desc):
        self.executable = executable
        self.todo = todo
        self.vec_mov = vec_mov
        self.desc = desc

    def build(self):
        global do_compile_fmt

        defs = ""
        defs += " -DTODO={}".format(self.todo)
        defs += " -Dvec_mov={}".format(self.vec_mov)

        compile_cmd = do_compile_fmt.format(defs, self.executable,
                                            self.executable)
        return os.system(compile_cmd) == 0

    def execute(self, perf_append):
        global do_exec_fmt
        global do_perf

        perf_cmd = "{}{} {}".format(do_perf, perf_append,
                                    do_exec_fmt.format(self.executable))
        print("######################################################################")
        print(self.desc)
        ret = os.system(perf_cmd) == 0
        print("######################################################################")
        return ret

    def run(self):
        global perf_bandwidth_events

        assert self.build(), "Error building"
        if not self.execute(perf_bandwidth_events):
            print("Unable to execute tracking relevant bandwidth counters")
            assert self.execute("")


confs = []
executables = ["stosb-low-bandwidth"]
for executable in executables:
    confs.append(Config(executable, 0, "vmovu", "Cachable VEC Loop"))
    confs.append(Config(executable, 0, "vmovnt", "Non-Cachable VEC Loop"))
    confs.append(Config(executable, 1, "vmovu", "rep stosb"))

for conf in confs:
    conf.run()
