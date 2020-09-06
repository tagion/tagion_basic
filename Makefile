include git.mk

DC?=dmd
AR?=ar
include $(REPOROOT)/command.mk

include setup.mk

-include $(REPOROOT)/dfiles.mk

BIN:=bin/
LDCFLAGS+=$(LINKERFLAG)-L$(BIN)
ARFLAGS:=rcs
BUILD?=$(REPOROOT)/build
#SRC?=$(REPOROOT)

.SECONDARY: $(TOUCHHOOK)
.PHONY: ddoc makeway


INCFLAGS=${addprefix -I,${INC}}

LIBRARY:=$(BIN)/$(LIBNAME)
LIBOBJ:=${LIBRARY:.a=.o};

REVISION:=$(REPOROOT)/$(SOURCE)/revision.di
.PHONY: $(REVISION)
.SECONDARY: .touch

ifdef COV
RUNFLAGS+=--DRT-covopt="merge:1 dstpath:reports"
DCFLAGS+=-cov
endif


ifndef DFILES
include $(REPOROOT)/source.mk
endif

HELP+=help-main
# DDOC help
-include $(DDOCBUILDER)

help-master: $(HELP)
	@echo "make lib       : Builds $(LIBNAME) library"
	@echo
	@echo "make test      : Run the unittests"
	@echo

help-main:
	@echo "Usage "
	@echo
	@echo "make info      : Prints the Link and Compile setting"
	@echo
	@echo "make proper    : Clean all"
	@echo
	@echo "make PRECMD=   : Verbose mode"
	@echo "                 make PRECMD= <tag> # Prints the command while executing"
	@echo

info:
	@echo "WAYS    =$(WAYS)"
	@echo "DFILES  =$(DFILES)"
#	@echo "OBJS    =$(OBJS)"
	@echo "LDCFLAGS=$(LDCFLAGS)"
	@echo "DCFLAGS =$(DCFLAGS)"
	@echo "INCFLAGS=$(INCFLAGS)"

include $(REPOROOT)/revsion.mk

ifndef DFILES
lib: dfiles.mk
	$(MAKE) lib

test: lib
	$(MAKE) test
else
lib: $(REVISION) $(LIBRARY)

unittest: $(UNITTEST)
	export LD_LIBRARY_PATH=$(LIBBRARY_PATH); $(UNITTEST)

$(UNITTEST):
	$(PRECMD)$(DC) $(DCFLAGS) $(INCFLAGS) $(DFILES) $(TESTDCFLAGS) $(OUTPUT)$@
#$(LDCFLAGS)

endif

define LINK
$(1): $(1).d $(LIBRARY)
	@echo "########################################################################################"
	@echo "## Linking $(1)"
#	@echo "########################################################################################"
	$(PRECMD)$(DC) $(DCFLAGS) $(INCFLAGS) $(1).d $(OUTPUT)$(BIN)/$(1) $(LDCFLAGS)
endef

$(eval $(foreach main,$(MAIN),$(call LINK,$(main))))

makeway: ${WAYS}

include $(REPOROOT)/makeway.mk
$(eval $(foreach dir,$(WAYS),$(call MAKEWAY,$(dir))))

%.touch:
	@echo "########################################################################################"
	@echo "## Create dir $(@D)"
	$(PRECMD)mkdir -p $(@D)
	$(PRECMD)touch $@


-include $(DDOCBUILDER)

%.o: %.c
	@echo "########################################################################################"
	@echo "## compile "$(notdir $<)
	$(PRECMD)gcc  -m64 $(CFLAGS) -c $< -o $@


$(LIBRARY): ${DFILES}
	@echo "########################################################################################"
	@echo "## Library $@"
	@echo "########################################################################################"
	${PRECMD}$(DC) ${INCFLAGS} $(DCFLAGS) $(DFILES) -c $(OUTPUT)$(LIBRARY)

CLEANER+=clean

clean:
	rm -f $(LIBRARY)
	rm -f ${OBJS}

proper: $(CLEANER)
	rm -fR $(WAYS)

$(PROGRAMS):
	$(DC) $(DCFLAGS) $(LDCFLAGS) $(OUTPUT) $@
