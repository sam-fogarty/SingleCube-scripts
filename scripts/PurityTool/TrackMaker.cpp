//some standard C++ includes
#include <iostream>
#include <stdlib.h>
#include <string>
#include <vector>
#include <chrono>
#include <cmath>
#include <iterator>
#include <algorithm>
#include <fstream>
#include <numeric>

//some ROOT includes
#include "TInterpreter.h"
#include "TROOT.h"
#include "TTree.h"
#include "TFile.h"
#include "TChain.h"
#include "TH1.h"
#include "TH2.h"
#include "TH3.h"
#include "TProfile2D.h"
#include "TPad.h"
#include "TCanvas.h"
#include "TStyle.h"
#include "TGaxis.h"
#include "TMath.h"
#include "TGraph.h"
#include "TPaletteAxis.h"
#include "TLegend.h"
#include "TVector3.h"
#include "TTreeReader.h"
#include "TTreeReaderArray.h"
#include "TVirtualFFT.h"

//special includes
#include "dbscan.h"

using namespace std;
using namespace std::chrono;

const double timeSF = 6.5;
//const double scanRadius = 10.0;
//const double scanRadius = 25.0;
const double scanRadius = 50.0; // CSU SingleCube Run 3
//const double scanRadius = 100.0; // CSU SingleCube Run 2
//const int minClusterSize = 50;
//const int minClusterSize = 8; // CSU SingleCube Run 2
const int minClusterSize = 20; // CSU SingleCube Run 3

const int dataChunkSize = 38400;
const int maxEvents = 10000000;

int main(int argc, char **argv)
{
  ///////////////////////////////////
  // Set Plot Formatting Options
  ///////////////////////////////////

  gErrorIgnoreLevel = kError;
  double stops[5] = {0.00,0.34,0.61,0.84,1.00};
  double red[5] = {0.00,0.00,0.87,1.00,0.51};
  double green[5] = {0.00,0.81,1.00,0.20,0.00};
  double blue[5] = {0.51,1.00,0.12,0.00,0.00};
  TColor::CreateGradientColorTable(5,stops,red,green,blue,255);
  gStyle->SetNumberContours(255);
  gStyle->SetOptStat(0);

  ///////////////////////////////////
  // Get Input File Name
  ///////////////////////////////////

  Char_t *inputfilename = (Char_t*)"";
  if (argc < 2)
  {
    cout << endl << "No input file name specified!  Aborting." << endl << endl;
    return -1;
  }
  else
  {
    inputfilename = argv[1];
  }

  ///////////////////////////////////
  // Set Up Pixel Map
  ///////////////////////////////////
  
  double pixelXvals[120][64] = {0.0};
  double pixelYvals[120][64] = {0.0};

  ifstream mapfile;
  mapfile.open("channelmap.dat");

  string string_chip;
  string string_channel;
  string string_X;
  string string_Y;

  int input_chip;
  int input_channel;
  double input_X;
  double input_Y;

  while(getline(mapfile,string_chip,' '))
  {
    getline(mapfile,string_channel,' ');
    getline(mapfile,string_X,' ');
    getline(mapfile,string_Y);
    
    input_chip = atoi(string_chip.c_str());
    input_channel = atoi(string_channel.c_str());
    input_X = atof(string_X.c_str());
    input_Y = atof(string_Y.c_str());

    pixelXvals[input_chip][input_channel] = input_X;
    pixelYvals[input_chip][input_channel] = input_Y;
  }
  
  ///////////////////////////////////
  // Set Up Output File
  ///////////////////////////////////

  TFile *outputFile = new TFile("analysis.root","RECREATE");
  outputFile->cd();

  int eventNum;
  int trackNum;
  double minT_X;
  double minT_Y;
  double minT_T;
  double maxT_X;
  double maxT_Y;
  double maxT_T;
  vector<double> trackHitX;
  vector<double> trackHitY;
  vector<double> trackHitT;
  vector<double> trackHitC;

  TTree *trackTree = new TTree("trackTree","");
  trackTree->Branch("eventNum",&eventNum);
  trackTree->Branch("trackNum",&trackNum);
  trackTree->Branch("minT_X",&minT_X);
  trackTree->Branch("minT_Y",&minT_Y);
  trackTree->Branch("minT_T",&minT_T);
  trackTree->Branch("maxT_X",&maxT_X);
  trackTree->Branch("maxT_Y",&maxT_Y);
  trackTree->Branch("maxT_T",&maxT_T);
  trackTree->Branch("trackHitX",&trackHitX);
  trackTree->Branch("trackHitY",&trackHitY);
  trackTree->Branch("trackHitT",&trackHitT);
  trackTree->Branch("trackHitC",&trackHitC);

  ///////////////////////////////////
  // Load Input Data
  ///////////////////////////////////

  TFile* inputfile = new TFile(inputfilename,"READ");
  
  TTreeReader reader("tree", inputfile);
  TTreeReaderValue<unsigned char> adc_counts(reader, "adc_counts");
  TTreeReaderValue<unsigned long long> timestamp(reader, "timestamp");
  //TTreeReaderValue<unsigned long long> chip_id(reader, "chip_id");
  TTreeReaderValue<unsigned char> chip_id(reader, "chip_id");
  //TTreeReaderValue<unsigned long long> channel_id(reader, "channel_id");
  TTreeReaderValue<unsigned char> channel_id(reader, "channel_id");

  ///////////////////////////////////
  // Loop Over Data
  ///////////////////////////////////

  eventNum = 0;
  trackNum = 0;
  int entryNum = 0;
  vector<vector<double>> hits;
  vector<vector<double>> hits_scaled;

  while (reader.Next())
  {
    if(eventNum >= maxEvents)
    {
      break;
    }
    else if((entryNum % dataChunkSize == 0) && (entryNum != 0))
    {
      auto dbscan = DBSCAN<std::vector<double>, double>();
      
      dbscan.Run(&hits_scaled,3,scanRadius,4);
      auto noise = dbscan.Noise;
      auto clusters = dbscan.Clusters;
      
      for(int i = 0; i < (int) clusters.size(); i++)
      {
        const int clusterSize = clusters.at(i).size();
        if(clusterSize > minClusterSize)
        {
          minT_X = 9999999999;
          minT_Y = 9999999999;
          minT_T = 9999999999;
          maxT_X = -9999999999;
          maxT_Y = -9999999999;
          maxT_T = -9999999999;
      
          trackHitX.clear();
          trackHitY.clear();
          trackHitT.clear();
          trackHitC.clear();
      
          for(int j = 0; j < clusterSize; j++)
          {
            const int hitIndex = clusters.at(i).at(j);
      
            trackHitX.push_back(hits[hitIndex][0]);
            trackHitY.push_back(hits[hitIndex][1]);
            trackHitT.push_back(hits[hitIndex][2]);
            trackHitC.push_back(hits[hitIndex][3]);
      
            if(hits[hitIndex][2] < minT_T)
      	    {
              minT_X = hits[hitIndex][0];
              minT_Y = hits[hitIndex][1];
              minT_T = hits[hitIndex][2];
      	    }
            if(hits[hitIndex][2] > maxT_T)
      	    {
              maxT_X = hits[hitIndex][0];
              maxT_Y = hits[hitIndex][1];
              maxT_T = hits[hitIndex][2];
      	    }
          }
      
          trackTree->Fill();
      
          trackNum++;
        }
      }

      hits.clear();
      hits_scaled.clear();
      entryNum = 0;
      eventNum++;
    }
    else
    {
      if((*chip_id < 11) || (*chip_id > 110) || (*channel_id < 0) || (*channel_id > 63))
      {
	entryNum++;
        continue;
      }
      
      double Xval, Yval, Tval, Cval;
      Xval = pixelXvals[*chip_id][*channel_id];
      Yval = pixelYvals[*chip_id][*channel_id];
      Tval = (double) *timestamp;
      Cval = (double) *adc_counts;

      if((Xval == 0.0) && (Yval == 0.0))
      {
	entryNum++;
        continue;
      }

      vector<double> hit;
      hit.push_back(Xval);
      hit.push_back(Yval);
      hit.push_back(Tval);
      hit.push_back(Cval);

      vector<double> hit_scaled;
      hit_scaled.push_back(Xval);
      hit_scaled.push_back(Yval);
      hit_scaled.push_back(Tval/timeSF);      

      hits.push_back(hit);
      hits_scaled.push_back(hit_scaled);
      
      entryNum++;
    }
  }

  ///////////////////////////////////
  // Write Output File
  ///////////////////////////////////

  outputFile->cd();
  trackTree->Write();
  outputFile->Close();

  return 0;
}
