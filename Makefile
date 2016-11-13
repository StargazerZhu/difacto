# default configures, one can change it by passing new value to make.
# e.g. `make CXX=g++-4.9`
CXX = g++
DEPS_PATH = $(shell pwd)/deps
USE_CITY=0
USE_LZ4=1
NO_REVERSE_ID=0
DMLC_CORE = dmlc-core
ROOTDIR = $(CURDIR)
config = make/config.mk

all: build/difacto

include $(config)
include ps-lite/make/deps.mk
include dmlc-core/make/dmlc.mk

INCPATH = -I./src -I./include -I./dmlc-core/include -I./ps-lite/include -I./dmlc-core/src -I$(DEPS_PATH)/include
PROTOC = ${DEPS_PATH}/bin/protoc
CFLAGS = -std=c++11 -fopenmp -fPIC -O3 -ggdb -Wall -finline-functions $(INCPATH) -DDMLC_LOG_FATAL_THROW=0 $(ADD_CFLAGS)


ifeq ($(NO_REVERSE_ID), 1)
CFLAGS += -DREVERSE_FEATURE_ID=0
endif


ifeq ($(USE_CITY), 1)
DEPS += ${CITYHASH}
CFLAGS += -DDIFACTO_USE_CITY=1
LDFLAGS += ${DEPS_PATH}/lib/libcityhash.a
endif

ifeq ($(USE_LZ4), 1)
DEPS += ${LZ4}
CFLAGS += -DDIFACTO_USE_LZ4=1
LDFLAGS += ${DEPS_PATH}/lib/liblz4.a
endif


LDFLAGS += $(DMLC_LDFLAGS)

# LDFLAGS += $(addprefix $(DEPS_PATH)/lib/, libprotobuf.a libzmq.a)

OBJS = $(addprefix build/, loss/loss.o \
updater.o \
sgd/sgd_updater.o sgd/sgd_learner.o \
learner.o \
bcd/bcd_learner.o \
lbfgs/lbfgs_learner.o \
store/store.o \
tracker/tracker.o \
reporter/reporter.o \
data/localizer.o reader/batch_reader.o )

DMLC_DEPS = dmlc-core/libdmlc.a


clean:
	rm -rf build/*
	make -C dmlc-core clean
	make -C ps-lite clean

lint:
	python2 dmlc-core/scripts/lint.py difacto all include src tests/cpp


build/%.o: src/%.cc ${DEPS}
	@mkdir -p $(@D)
	$(CXX) $(INCPATH) -std=c++0x -MM -MT build/$*.o $< >build/$*.d
	$(CXX) $(CFLAGS) -c $< -o $@

build/libdifacto.a: $(OBJS)
	ar crv $@ $(filter %.o, $?)

build/difacto: build/main.o build/libdifacto.a $(DMLC_DEPS)
	$(CXX) $(CFLAGS) -o $@ $^ $(LDFLAGS)

dmlc-core/libdmlc.a:
	+ cd $(DMLC_CORE); $(MAKE) libdmlc.a config=$(config); cd $(ROOTDIR)


include tests/cpp/test.mk


test: build/difacto_tests

-include build/*.d
-include build/*/*.d
