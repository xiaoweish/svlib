#- Makefile for unit-test invocation
#-

.PHONY: ius vcs questa clean
ius:
	runSVUnit -s $@

vcs:
	runSVUnit -s $@

questa:
	runSVUnit -s $@

clean:
	-rm -f *.log *.history .svunit.f *.vstf
	-rm -rf xcelium.d work

# end
