#CXXFLAGS += -I. $(shell root-config --cflags) -g
#LDFLAGS += $(shell root-config --libs) -lPhysics -lMatrix -g
CXXFLAGS += -I. $(shell root-config --cflags) -I/usr/lib/x86_64-linux-gnu/hdf5/serial/include -g
LDFLAGS += $(shell root-config --libs) -lPhysics -lMatrix -L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5_cpp -lhdf5 -g

CLASSES = kdtree
#PROGRAMS = TrackMaker TrackMakerMultiTile PurityStudy dEdxStudy PedestalAnalysis H5toROOT
PROGRAMS = TrackMaker PurityStudy H5toROOT

all:	clean $(CLASSES) $(PROGRAMS) clean2

$(CLASSES):
	@echo '<<building' $@' object file>>'
	@$(CXX) -c $@.cpp -o $@.o $(CXXFLAGS) $(LDFLAGS)
	@rm -rf *.dSYM
$(PROGRAMS):
	@echo '<<compiling' $@'>>'
	@$(CXX) $@.cpp *.o -o $@ $(CXXFLAGS) $(LDFLAGS)
	@rm -rf *.dSYM
clean:	
	rm -f $(PROGRAMS)
clean2:
	rm -f *.o
