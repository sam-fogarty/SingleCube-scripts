////////////////////////////////////////////////////////////////////////
// This is a program to rotate the geometry made with makeSCgeom.C to match DUNE ND geometry
// This program requires root, run using `root -x rotateGeom.C'
///////////////////////////////////////////////////////////////////////

#include <iostream>
using namespace std;

void rotateGeom()

{

 gSystem->Load("libGeom");

 TFile *f = TFile::Open("geometries/SingleCubeTest.root");
 TGeoManager *geo = (TGeoManager*)f->Get("Default");
 TGeoVolume *SingleCube = geo->GetVolume("outerAirVolume"); 

 TGeoElementTable *table = gGeoManager->GetElementTable();
 TGeoMixture *air = new TGeoMixture("air",2,1.29);

 TGeoElement *N = table->FindElement("N");
 TGeoElement *O = table->FindElement("O");

 air->AddElement(N,0.7);
 air->AddElement(O,0.3);
 TGeoMedium *airMed = new TGeoMedium("airMed",1,air);

 double worldx = 5000./2.;
 double worldy = 5000./2.;
 double worldz = 5000./2.;
 TGeoVolume *world = gGeoManager->MakeBox("world",airMed,worldx,worldy,worldz);
 //TGeoVolume *world = new TGeoVolume("world",airMed,worldx,worldy,worldz);

 TGeoRotation *coord = new TGeoRotation("coord",180.,90.,45.);
 //TGeoRotation *rCube = new TGeoRotation("rCube",45.0,0.,0.);
 //double cubedist = 15.13615/sqrt(2.0);
 TGeoCombiTrans *cSingleCube = new TGeoCombiTrans("cSingleCube",0.,0.,15.495,coord);
 //TGeoCombiTrans *cCube = new TGeoCombiTrans("cCube",0.,0.,0.,rCube);
 
 //outerAirVolume->AddNode(comp2,1,ccomp2);
 //outerAirVolume->AddNode(parab_GAr,1,cparab_GAr);
 
 // define top volume
 TGeoVolume *top = world;

 gGeoManager->SetTopVolume(top);

 top->AddNode(SingleCube,1,cSingleCube);

 gGeoManager->CloseGeometry();
 
 // set colors
 //bucket->SetLineColor(kMagenta);
 //bucket_steelLayer1->SetLineColor(kMagenta);
 //bucket_steelLayer1->SetLineStyle(kDotted);
 

 gGeoManager->SetTopVisible(); // the TOP is invisible
 top->Draw();
 // checks for overlaps
 //double precision = 0.0001;
 //gGeoManager->CheckOverlaps(precision, "d");

 gGeoManager->Export("geometries/SingleCubeTestRotated.root");
 gGeoManager->Export("geometries/SingleCubeTestRotated.gdml");

}
