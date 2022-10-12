////////////////////////////////////////////////////////////////////////
// This is a program to generate a geometry for the SingleCube
// LArTPC detector at CSU. 
// This program requires and is run by ROOT, which you can install by running:
// source /dune/app/users/kordosky/nd_sim/dune_nd_setup.sh
///////////////////////////////////////////////////////////////////////

#include <iostream>
using namespace std;

void GDMLtoROOT()

{

 gSystem->Load("libGeom");
 //gSystem->Load("libGdml");
 //TFile *f = TFile::Open("SingleCube.root");
 //TGeoManager::Import("SingleCube.gdml");
 TGeoManager *geo = new TGeoManager();
 geo->Import("SingleCube.gdml");
 
 //TFile *f = TFile::Open("/dune/data/users/sfogarty/DUNE-Geometries/SingleCube.root");
 
 TGeoVolume *LArCube = geo->GetTopVolume();
 //LArCube->Draw();
 
 TGeoVolume *top = LArCube;
 TObjArray *volumes = geo->GetListOfVolumes();
 Int_t nvolumes = volumes->GetEntries();
 TGeoVolume *V = NULL;
 TObjArray *nodes = top->GetNodes();
 TGeoNode *node = NULL;
 TGeoMatrix *matrix = NULL;
 
 for ( int i = 0; i < nvolumes; i++ ){
   if (V != top)
   {
   V = (TGeoVolume*)volumes->At(i);
   node = (TGeoNode*)nodes->At(i);
   matrix = node->GetMatrix();
   V->SetVisContainers(kTRUE);
   top->AddNode(V,1, matrix);
   }

 }
 gGeoManager->SetTopVolume(top);
 
 //TGeoVolume *top = gGeoManager->GetTopVolume();
 //TGeoVolume *master = gGeoManager->GetMasterVolume();
 //TGeoVolume *vol1 = gGeoManager->GetVolume("volTPCPCB");
 //TGeoVolume *vol2 = gGeoManager->GetVolume("volTPCPixel");
 //TGeoVolume *vol3 = gGeoManager->GetVolume("volTPCAsic");
 //TGeoVolume *vol4 = gGeoManager->GetVolume("volPixelPlane");
 //TGeoVolume *vol5 = gGeoManager->GetVolume("volTPB_LAr");
 //TGeoVolume *vol6 = gGeoManager->GetVolume("volSiPM");
 //TGeoVolume *vol7 = gGeoManager->GetVolume("volSiPM_Mask");
 //TGeoVolume *vol8 = gGeoManager->GetVolume("volSiPM_PCB");
 //TGeoVolume *vol9 = gGeoManager->GetVolume("volArCLight");
 //TGeoVolume *vol10 = gGeoManager->GetVolume("volPCBBar");
 //TGeoVolume *vol11 = gGeoManager->GetVolume("volOpticalDet");
 //TGeoVolume *vol12 = gGeoManager->GetVolume("volBracket");
 //TGeoVolume *vol13 = gGeoManager->GetVolume("volLAr");
 //TGeoVolume *vol14 = gGeoManager->GetVolume("volKapton");
 //TGeoVolume *vol15 = gGeoManager->GetVolume("volFieldCage");

 //TGeoVolume *LArCube = geo->GetVolume("volSingleCube");
 //top->AddNode(vol1,1);
 //top->AddNode(vol2,1);
 //top->AddNode(vol3,1);
 //top->AddNode(vol4,1);
 //top->AddNode(vol5,1);
 //top->AddNode(vol6,1);
 //top->AddNode(vol7,1);
 //top->AddNode(vol8,1);
 //top->AddNode(vol9,1);
 //top->AddNode(vol10,1);
 //top->AddNode(vol11,1);
 //top->AddNode(vol12,1);
 //top->AddNode(vol13,1);
 //top->AddNode(vol14,1);
 //top->AddNode(vol15,1);

 //top->Draw();
 //master->Draw();

 gGeoManager->CloseGeometry();
 geo->CloseGeometry();
 //top->Draw();
 
 gGeoManager->Export("SingleCubeTest.gdml");
 gGeoManager->Export("SingleCubeTest.root");
 //gGeoManager->Export("SingleCube.gdml");

}
