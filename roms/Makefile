binaries=cartboot-e000.prg nobasic-c000.prg

all: $(binaries)

%.prg: %.xa
	xa $< -o $@

clean:
	rm -f $(binaries)
