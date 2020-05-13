binaries=cartboot-fc00.prg nobasic-c000.prg nokernal-e000.prg

all: $(binaries)

%.prg: %.xa
	xa $< -o $@

clean:
	rm -f $(binaries)
