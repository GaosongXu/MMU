sim:
	./simv -l sim.log +notimingcheck +nospecify -k ucli.key +define+DUMP_FSDB  +fsdb+functions 

verdi:
	verdi -sv -f ./filelist.f -ssf mmu_tree.fsdb &

clean:
	rm -rf simv.daidir csrc DVEfiles verdiLog *.log  *.conf *.vpd *.key *.fsdb simv *.dump

collect_error:
	perl collect_vcs_error_warning.pl

compile:
	vcs +v2k -f ./filelist.f \
		-full64 \
		+define+DUMP_FSDB \
		-sverilog \
		-timescale=1ns/1ps \
		-debug_access+cbk+class \
		-debug_all \
		-l compile.log \
		-top mmu_tree_tb \
		-P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab \
		   ${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a \
                -o simv

run: clean compile sim