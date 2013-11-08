# Default target.
.DEFAULT_GOAL := build


# Print any variable requested
.PHONY: print_var-%
printvar-%:
	@echo '$*=$($*)'


# Eye candy.
# AVR Studio 3.x does not check make's exit code but relies on
# the following magic strings to be generated by the compile job.
.PHONY: begin
begin:
	@echo
	@echo $(MSG_BEGIN)

.PHONY: end
end:
	@echo $(MSG_END)
	@echo



# Help
HELP_TITTLE  = @printf "\n%s:\n"
HELP_DESC    = @printf   "  %s\n"
HELP_ATTRS   = @printf "\n  attributes:\n"
HELP_ATTR    = @printf   "    %-20s - %s\n"
HELP_TARGETS = @printf "\n  actions:\n"
HELP_TARGET  = @printf   "    %-20s - %s\n"

.PHONY: help common_help environment_help build_help program_help

environment_help: common_help
build_help: environment_help
program_help: build_help
help: program_help
common_help:
	@echo "usage: make <action>"
