TOP_DIR = ../.. 
DEPLOY_RUNTIME=/kb/runtime
TARGET ?= /kb/deployment
include $(TOP_DIR)/tools/Makefile.common

SERVICE_SPEC = GWAS.spec
SERVICE_NAME = GWAS
MODULE	     = GWAS
SERVICE_PORT = 7086
SERVICE_PSGI = lib/GWAS.psgi
SERVICE_DIR  = $(TARGET)/services/$(SERVICE_NAME)
SERVICE_TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(KB_RUNTIME) --define kb_service_name=$(SERVICE_NAME) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_psgi=$(SERVICE_PSGI)

# You can change these if you are putting your tests somewhere
# else or if you are not using the standard .t suffix
CLIENT_TESTS_PYTHON = $(wildcard client-tests/*.py)
SCRIPT_TESTS = $(wildcard script-tests/*.py)
CLIENT_TESTS = $(wildcard t/*.t)

default: all

all: compile-typespec

compile-typespec:
	compile_typespec \
		--psgi $(SERVICE_NAME).psgi \
		--impl Bio::KBase::$(SERVICE_NAME)::$(SERVICE_NAME)Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME)/Client \
		--js javascript/$(SERVICE_NAME)/Client \
		$(SERVICE_SPEC) lib	
#		--pyimpl biokbase.$(SERVICE_NAME).Impl \
#		--pyserver biokbase.$(SERVICE_NAME).Server \
	#rm lib/GWASImpl.pm lib/GWASServer.pm

# Test

test: test-client test-scripts
	@echo "running server, script and client tests"

test-scripts:
	for t in $(SCRIPT_TESTS) ; do \
		if [ -f $$t ] ; then \
			KB_TEST_CONFIG=test.cfg python $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

test-client:
	for t in $(CLIENT_TESTS_PYTHON) ; do \
		if [ -f $$t ] ; then \
			KB_TEST_CONFIG=test.cfg python $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done
	for t in $(CLIENT_TESTS) ; do \
	        if [ -f $$t ] ; then \
	                $(DEPLOY_RUNTIME)/bin/perl $$t ; \
	                if [ $$? -ne 0 ] ; then \
	                        exit 1 ; \
	                fi \
	        fi \
	done

# Deployment

include $(TOP_DIR)/tools/Makefile.common.rules

# here are the standard KBase deployment targets (deploy,deploy-client, deploy-scripts, & deploy-service)

deploy: deploy-libs deploy-scripts deploy-service


# Deploy client artifacts, including the application programming interface
# libraries, command line scripts, and associated reference documentation.

deploy-client: deploy-libs deploy-scripts deploy-docs

# Deploy command line scripts.  The scripts are "wrapped" so users do not
# need to modify their environment to run KBase scripts.

# Deploy documentation of the application programming interface.
# (Waiting for resolution on documentation of command line scripts).
	
deploy-docs: build-docs
	if [ ! -d $(SERVICE_DIR)/webroot ] ; then mkdir -p $(SERVICE_DIR)/webroot ; fi
	cp docs/*html $(SERVICE_DIR)/webroot/.
	
build-docs:
	if [ ! -d docs ] ; then mkdir -p docs ; fi
	pod2html -t "GWAS" lib/Bio/KBase/GWAS/Client.pm > docs/GWAS.html
	
# Deploy service start and stop scripts.

deploy-service: deploy-cfg
	if [ ! -d $(SERVICE_DIR) ] ; then mkdir -p $(SERVICE_DIR) ; fi
	tpage $(SERVICE_TPAGE_ARGS) service/start_service.tt > $(SERVICE_DIR)/start_service; \
	chmod +x $(SERVICE_DIR)/start_service; \
	tpage $(SERVICE_TPAGE_ARGS) service/stop_service.tt > $(SERVICE_DIR)/stop_service; \
	chmod +x $(SERVICE_DIR)/stop_service; \
	tpage $(SERVICE_TPAGE_ARGS) service/process.tt > $(SERVICE_DIR)/process.$(SERVICE_NAME); \
	chmod +x $(SERVICE_DIR)/process.$(SERVICE_NAME); 
	mkdir -p $(SERVICE_DIR)/awf
	cat deploy.cfg service.cfg > $(SERVICE_DIR)/service.cfg;

# the above service.cfg is not correct at the moment
