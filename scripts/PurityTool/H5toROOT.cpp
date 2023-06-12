#include <string>
#include <iostream>
#include <cassert>
#include <vector>
#include <fstream>

#include "TROOT.h"
#include "TFile.h"
#include "TNtuple.h"
#include "TLeafD.h"
#include "TStopwatch.h"

#include <H5Cpp.h>

namespace {

  char map_h5type_to_root(H5::DataType type) {

    if(type == H5::PredType::STD_U8LE){
      return 'b';
    }
    if(type == H5::PredType::STD_U16LE){
      return 's';
    }
    if(type == H5::PredType::STD_U32LE){
      return 'i';
    }
    if(type == H5::PredType::STD_U64LE){
      return 'l';
    }

    bool h5_predtype_not_known = false;
    assert(h5_predtype_not_known);
    return ' ';
  }
};

int main(int argc, char * argv[])
{
  using namespace std;
  using namespace H5;

  TStopwatch timer;
  timer.Start();
  
  // h5toroot <h5 file name> <root file name>
  if(argc != 3){
    cout << "Usage: " << argv[0] << " <hdffile> <hdf5 dataset name> <root file name>\n";
    exit(1);
  }

  const string filename(argv[1]);
  const string rootfile(argv[2]);

  const string tablename("packets");
  
  H5File h5 = H5File(filename, H5F_ACC_RDONLY);
  Group root = h5.openGroup("/");
  DataSet ds = root.openDataSet(tablename);

  DataSpace dsp = ds.getSpace();
  if(dsp.getSimpleExtentNdims() != 1){
    cout << "Cannot handle tables with rank != 1.";
    exit(1);
  }

  const hssize_t nrecs = dsp.getSimpleExtentNpoints();
  const CompType type = ds.getCompType();
  const int nm = type.getNmembers();
  const size_t twidth = type.getSize();

  TTree * rtree = new TTree("table", "");

  string description;

  vector<size_t> offsets(nm);
  vector<char> rflags(nm);
  for(int k = 0; k < nm; ++k) {
    offsets[k] = type.getMemberOffset(k);
    rflags[k] = map_h5type_to_root(type.getMemberDataType(k));
    description += type.getMemberName(k) + "/" + rflags[k] + ":";
  }
  description.erase(description.size() - 1);

  hsize_t dims[] = { 1 };
  hsize_t count[] = { 1 };
  hsize_t offset[] = { 0 };
  DataSpace mem(1,dims);

  char *data = new char[twidth];
  rtree->Branch("data", data, description.c_str());

  for(size_t k = 0; k < nrecs; ++k){
    dsp.selectHyperslab(H5S_SELECT_SET, count, offset, 0, dims);
    ds.read(data, type, mem, dsp);
    rtree->Fill();
    offset[0] += count[0];
  }

//  int tilemap[5][40] = {0};
//
//  ifstream tilemapfile;
//  tilemapfile.open("tilemapping_multitile.dat");
//
//  string string_iog;
//  string string_ioc;
//  string string_tile;
//
//  int input_iog;
//  int input_ioc;
//  int input_tile;
//
//  while(getline(tilemapfile,string_iog,' '))
//  {
//    getline(tilemapfile,string_ioc,' ');
//    getline(tilemapfile,string_tile);
//    
//    input_iog = atoi(string_iog.c_str());
//    input_ioc = atoi(string_ioc.c_str());
//    input_tile = atoi(string_tile.c_str());
//
//    tilemap[input_iog][input_ioc] = input_tile;
//  }
//
//  tilemapfile.close();

  UChar_t chip;
  UChar_t chan;
  UChar_t iog;
  UChar_t ioc;
  UChar_t pt;
  UChar_t vp;
  UChar_t adc;
  ULong64_t ts;
 
  TBranch *tpcdata = (TBranch*) rtree->GetBranch("data");

  TLeaf *l_chip = (TLeaf*) tpcdata->GetLeaf("chip_id");
  l_chip->SetAddress(&chip);
  TLeaf *l_chan = (TLeaf*) tpcdata->GetLeaf("channel_id");
  l_chan->SetAddress(&chan);
  TLeaf *l_iog = (TLeaf*) tpcdata->GetLeaf("io_group");
  l_iog->SetAddress(&iog);
  TLeaf *l_ioc = (TLeaf*) tpcdata->GetLeaf("io_channel");
  l_ioc->SetAddress(&ioc);
  TLeaf *l_pt = (TLeaf*) tpcdata->GetLeaf("packet_type");
  l_pt->SetAddress(&pt);
  TLeaf *l_vp = (TLeaf*) tpcdata->GetLeaf("valid_parity");
  l_vp->SetAddress(&vp);
  TLeaf *l_adc = (TLeaf*) tpcdata->GetLeaf("dataword");
  l_adc->SetAddress(&adc);
  TLeafD *l_ts = (TLeafD*) tpcdata->GetLeaf("timestamp");
  l_ts->SetAddress(&ts);

  TFile * rfile = new TFile(rootfile.c_str(),"RECREATE");
  TTree * rtree2 = new TTree("tree", "");

  unsigned char adc_counts;
  //unsigned char tile_id;
  unsigned char chip_id;
  unsigned char channel_id;
  unsigned char io_group;
  unsigned char packet_type;
  unsigned long long timestamp;
  
  rtree2->Branch("adc_counts", &adc_counts);
  //rtree2->Branch("tile_id", &tile_id);
  rtree2->Branch("chip_id", &chip_id);
  rtree2->Branch("channel_id", &channel_id);
  rtree2->Branch("io_group", &io_group);
  rtree2->Branch("packet_type", &packet_type);
  rtree2->Branch("timestamp", &timestamp);

  Long64_t nentries = rtree->GetEntries();
  for(Long64_t i = 0; i < nentries; i++)
  {
    rtree->GetEntry(i);

    if((pt > 3) || ((vp == 1) && ((pt > 0) || (ts > 0))))
    //if((pt > 3) || ((vp == 1) && ((pt > 0) || ((ts > 1000000) && (ts < 11000000)))))
    {
      adc_counts = adc;
      //tile_id = tilemap[iog][ioc];
      chip_id = chip;
      channel_id = chan;
      io_group = iog;
      packet_type = pt;
      timestamp = ts;

      rtree2->Fill();
    }
  }
  
  rfile->Write();

  timer.Stop();
  cout << "ROOT File Production Time:  " << timer.CpuTime() << " sec." << endl;

  return 0;
}
