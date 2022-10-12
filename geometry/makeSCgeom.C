////////////////////////////////////////////////////////////////////////
// This is a program to generate a geometry for the SingleCube LArTPC detector at CSU
// This program requires ROOT. Run using `root -x makeSCgeom.C'
// Dimensions in cm
///////////////////////////////////////////////////////////////////////

#include <iostream>
using namespace std;

void makeSCgeom()

{

 gSystem->Load("libGeom");

 // import TPC geometry
 TFile *f = TFile::Open("geometries/SingleCube.root");
 TGeoManager *geo = (TGeoManager*)f->Get("Default");
 TGeoVolume *LArCube = geo->GetTopVolume();

 // define LAr material and medium
 TGeoElementTable *table = gGeoManager->GetElementTable();
 TGeoElement *Ar = table->FindElement("Argon");
 Ar->Print();
 TGeoMaterial *LAr = new TGeoMaterial("LAr", Ar, 1.3954);
 LAr->Print();
 TGeoMedium *LArMed = new TGeoMedium("LArMed",1, LAr);

 // make bucket to put TPC in
 double bucket_thickness = 0.00127*100.;
 double bucket_rmin = 0.;
 double bucket_rmax = 0.3048 *100. - bucket_thickness;
 double bucket_heightover2 = 0.6096/2.0 *100.;
 double bucket_steelLayer_thickness = bucket_thickness;

 TGeoTube *bucket_i = new TGeoTube("bucket_i", bucket_rmin,
              bucket_rmax,bucket_heightover2);
 TGeoTube *bucketwiththickness_i = new TGeoTube("bucketwiththickness_i", bucket_rmin,
              bucket_rmax+bucket_steelLayer_thickness,bucket_heightover2 + bucket_steelLayer_thickness);
 
 TGeoBBox *cube_cutout = new TGeoBBox("lcco",31.75875/2.0,34.0022/2.0,32.69235/2.0);
 TGeoRotation *rCube = new TGeoRotation("rCube",45.0,0.,0.);
 rCube->RegisterYourself();

 TGeoCompositeShape *sbucket = new TGeoCompositeShape("sbucket","bucket_i-(lcco:rCube)");
 TGeoVolume *bucket = new TGeoVolume("bucket",sbucket,LArMed);

 double xGArCyl = 0.11013 * 100.;
 double yGArCyl = 0.030582*100.;
 double zGArCyl = 0.01016*100.;
 TGeoTranslation *cGArCyl = new TGeoTranslation("cGArCyl",xGArCyl,yGArCyl,zGArCyl);
 cGArCyl->RegisterYourself();

 ////// Make gaseous argon material, and GAr cylinder

 TGeoMaterial *GAr = new TGeoMaterial("GAr", Ar, 0.001656);
 GAr->Print();

 TGeoMedium *GArMed = new TGeoMedium("GArMed",1,GAr);
 double GArCyl_steelLayer_thickness = 0.003175*100.; // eigth inch, kind of a guess
 // outer diameter measured to surface; inner diameter measured to inner most steel surface
 
 double GArCyl_thickness = 0.9652/2.0 *100. - 2*GArCyl_steelLayer_thickness - 0.9144/2. *100.; // vacuum layer
 double GArCyl_rmin = 0.;
 double GArCyl_rmax = 0.9144/2.0 *100.; // just inner radius
 double GArCyl_heightover2 = 1.23825/2.0 * 100.;

 TGeoTube *GArCylinder_i = new TGeoTube("GArCylinder_i", GArCyl_rmin,
              GArCyl_rmax,GArCyl_heightover2);
 TGeoCompositeShape *GArC = new TGeoCompositeShape("GArC","(GArCylinder_i:cGArCyl) - bucketwiththickness_i");
 TGeoVolume *GArCylinder = new TGeoVolume("GArCylinder",GArC,GArMed);
 
 // make stainless steel material to layer the cylinders
 TGeoMixture *stainlessSteel = new TGeoMixture("stainlessSteel", 5, 8.02);

 TGeoElement *Mn = table->FindElement("Mn");
 TGeoElement *Si = table->FindElement("Si");
 TGeoElement *Cr = table->FindElement("Cr");
 TGeoElement *Ni = table->FindElement("Ni");
 TGeoElement *Fe = table->FindElement("Fe");

 stainlessSteel->AddElement(Mn, 0.02);
 stainlessSteel->AddElement(Si, 0.01);
 stainlessSteel->AddElement(Cr, 0.19);
 stainlessSteel->AddElement(Ni, 0.10);
 stainlessSteel->AddElement(Fe, 0.68);
 stainlessSteel->Print(); 

 TGeoMedium *steelMed = new TGeoMedium("steelMed",1,stainlessSteel);

 ///// make bucket top, i.e. the square cut-out cover. 
 ///// example of making a composite shape
 double boxlength = sqrt(2.0)*bucket_rmax;
 TGeoBBox *cutout = new TGeoBBox("BS",boxlength/2.0,boxlength/2.0,bucket_thickness/2.0);
 TGeoTube *circle = new TGeoTube("BC",bucket_rmin,bucket_rmax,bucket_thickness/2.0);
 TGeoCompositeShape *cs2 = new TGeoCompositeShape("cs2","BC-BS");
 TGeoVolume *comp2 = new TGeoVolume("COMP2",cs2,steelMed);
 
 ///// making the different layers of the GAr Cylinder
 double GArCyl_steelLayer1_rmin = GArCyl_rmax;
 double GArCyl_steelLayer1_rmax = GArCyl_rmax + GArCyl_steelLayer_thickness; 
 double GArCyl_steelLayer1_heightover2 = GArCyl_heightover2;
 
 TGeoVolume *GArCyl_steelLayer1 = gGeoManager->MakeTube("GArCyl_steelLayer1", 
	   steelMed,GArCyl_steelLayer1_rmin,GArCyl_steelLayer1_rmax,
           GArCyl_steelLayer1_heightover2);

 // vacuum layer for GAr Cylinder, in between the two steel layers
 double GArCyl_vacuumLayer_rmin = GArCyl_steelLayer1_rmax;
 double GArCyl_vacuumLayer_rmax = GArCyl_steelLayer1_rmax + GArCyl_thickness;
 double GArCyl_vacuumLayer_heightover2 = GArCyl_heightover2;
 
 TGeoMaterial *vacuum = new TGeoMaterial("vacuum",0,0,1e-25);
 TGeoMedium *vacuumMed = new TGeoMedium("vacuumMed",1,vacuum);

 TGeoVolume *GArCyl_vacuumLayer = gGeoManager->MakeTube("GArCyl_vacuumLayer", 
	   vacuumMed,GArCyl_vacuumLayer_rmin,GArCyl_vacuumLayer_rmax,
           GArCyl_vacuumLayer_heightover2);

 double GArCyl_steelLayer2_rmin = GArCyl_vacuumLayer_rmax;
 double GArCyl_steelLayer2_rmax = GArCyl_vacuumLayer_rmax + GArCyl_steelLayer_thickness;
 double GArCyl_steelLayer2_heightover2 = GArCyl_heightover2;
 
 TGeoVolume *GArCyl_steelLayer2 = gGeoManager->MakeTube("GArCyl_steelLayer2", 
	   steelMed,GArCyl_steelLayer2_rmin,GArCyl_steelLayer2_rmax,
           GArCyl_steelLayer2_heightover2);

 ////// make stainless steel lid
 double steelCap_thickness = 0.0254 *100.;
 double steelCap_rmin = 0.;
 //double steelCap_rmax = 0.9652/2.0*100.;
 double steelCap_rmax = GArCyl_steelLayer2_rmax;
 double steelCap_heightover2 = steelCap_thickness/2.;

 TGeoVolume *steelCap = gGeoManager->MakeTube("steelCap", steelMed,
	   steelCap_rmin,steelCap_rmax, steelCap_heightover2);

 ////// make steel layer for bucket
 //double bucket_steelLayer_thickness = bucket_thickness;
 double bucket_steelLayer_rmin = bucket_rmax;
 double bucket_steelLayer_rmax = bucket_rmax + bucket_steelLayer_thickness;
 double bucket_steelLayer_heightover2 = bucket_heightover2;
 
 TGeoVolume *bucket_steelLayer = gGeoManager->MakeTube("bucket_steelLayer", 
	   steelMed,bucket_steelLayer_rmin,bucket_steelLayer_rmax,
           bucket_steelLayer_heightover2);

 double GArCyl_bottomVacuum_heightover2 = 0.3175/2.0 *100.;
 TGeoVolume *GArCyl_bottomVacuum_steelLayer = gGeoManager->MakeTube("GArCyl_bottomVacuum_steelLayer",steelMed,GArCyl_vacuumLayer_rmax,GArCyl_steelLayer2_rmax,GArCyl_bottomVacuum_heightover2);

 ////// make volume of air to contain the room and all remaining volumes

 // make air material, lab space, then outer air volume
 TGeoMixture *air = new TGeoMixture("air", 2, 1.29);

 TGeoElement *N = table->FindElement("N");
 TGeoElement *O = table->FindElement("O");

 air->AddElement(N, 0.7);
 air->AddElement(O, 0.3);
 air->Print();

 TGeoMedium *airMed = new TGeoMedium("airMed", 1, air);

 double bCyl_height = 0.3175*100/2.0;
 double bCyl_rmin = 0.0;
 double bCyl_rmax = GArCyl_vacuumLayer_rmax;

 double bSph_rmin = 0.0;
 double bSph_rmax = GArCyl_vacuumLayer_rmin;
 double bSph_theta1 = 0.0;
 double bSph_theta2 = 180.0;
 double bSph_phi1 = 0.0;
 double bSph_phi2 = 180.0;
 // uses paraboloid shape
 double bParab_rlo = GArCyl_vacuumLayer_rmax * 5./8.; //approximate
 double bParab_rhi = GArCyl_vacuumLayer_rmin;
 double bParab_dz = 0.15875/2.0 *100.;

 // lab space, just air
 double lab_side1over2 = 648/2;
 double lab_side2over2 = 975/2;
 double lab_side3over2 = 305/2; // seems to be the default direction of drift, z

 TGeoTranslation *scshift = new TGeoTranslation("scshift",xGArCyl,yGArCyl,zGArCyl - bCyl_height - steelCap_thickness/2.0 + steelCap_thickness);
 scshift->RegisterYourself();
 TGeoBBox *lab_i = new TGeoBBox("lab_i",lab_side1over2,
           lab_side2over2,lab_side3over2);
 double scube_height = GArCyl_heightover2*2.0 + steelCap_thickness + bCyl_height*2.0;
 TGeoTube *scube = new TGeoTube("scube",0.0,GArCyl_steelLayer2_rmax, scube_height/2.0);
 TGeoCompositeShape *lab_cutout = new TGeoCompositeShape("labco","lab_i - (scube:scshift)");
 TGeoVolume *lab = new TGeoVolume("lab",lab_cutout,airMed);
 
 // concrete material
 TGeoMixture *concrete = new TGeoMixture("concrete", 10, 2.4);

 TGeoElement *H = table->FindElement("H");
 TGeoElement *C = table->FindElement("C");
 //TGeoElement *O = table->FindElement("O");
 TGeoElement *Na = table->FindElement("Na");
 TGeoElement *Mg = table->FindElement("Mg");
 TGeoElement *Al = table->FindElement("Al");
 //TGeoElement *Si = table->FindElement("Si");
 TGeoElement *K = table->FindElement("K");
 TGeoElement *Ca = table->FindElement("Ca");
 //TGeoElement *Fe = table->FindElement("Fe");

 concrete->AddElement(H, 0.01);
 concrete->AddElement(C, 0.001);
 concrete->AddElement(O, 0.529107);
 concrete->AddElement(Na, 0.016);
 concrete->AddElement(Mg, 0.002);
 concrete->AddElement(Al, 0.033872);
 concrete->AddElement(Si, 0.337021);
 concrete->AddElement(K, 0.013);
 concrete->AddElement(Ca, 0.044);
 concrete->AddElement(Fe, 0.014);
 concrete->Print();

 TGeoMedium *concreteMed = new TGeoMedium("concreteMed", 1, concrete);

 // concrete cap
 double concreteCap_side1over2 = lab_side1over2;
 double concreteCap_side2over2 = lab_side2over2;
 double concreteCap_side3over2 = 100./2;

 TGeoVolume *concreteCap = gGeoManager->MakeBox("concreteCap",concreteMed,
            concreteCap_side1over2, concreteCap_side2over2,concreteCap_side3over2);

 TGeoBBox *CC_i = new TGeoBBox("CC_i",concreteCap_side1over2, concreteCap_side2over2,concreteCap_side3over2+lab_side3over2);

 // paraboid doesn't work with edep-sim, not implemented. Need to replace, or can neglect?
 //TGeoParaboloid *bParab = new TGeoParaboloid("P",bParab_rlo,bParab_rhi,bParab_dz);
 //TGeoParaboloid *bParab_GAr = new TGeoParaboloid("P2",bParab_rlo,bParab_rhi,bParab_dz);
 //TGeoRotation *r1 = new TGeoRotation("r1",-90.0,-90.0,0.0);
 //r1->RegisterYourself();
 //TGeoTranslation *tp = new TGeoTranslation("tp",0.0,0.0,bCyl_height-bParab_dz);
 //tp->RegisterYourself();
 //TGeoCompositeShape *cs = new TGeoCompositeShape("cs", "T-P:tp");
 //TGeoVolume *comp = new TGeoVolume("COMP",cs,vacuumMed);
 //TGeoVolume *parab_GAr = new TGeoVolume("parab_GAr",bParab_GAr,GArMed);
 TGeoVolume *bCyl = gGeoManager->MakeTube("bCyl",vacuumMed,bCyl_rmin,bCyl_rmax,bCyl_height);

 ///// outer air volume
 double outerAirVolume_side1over2 = 5000./2.; // dont know how big this needs to be. So it is thus real big for now.
 double outerAirVolume_side2over2 = 5000./2.;
 double outerAirVolume_side3over2 = 5000./2.;

 TGeoVolume *outerAirVolume = gGeoManager->MakeBox("outerAirVolume",airMed,
						   outerAirVolume_side1over2,outerAirVolume_side2over2,
              outerAirVolume_side3over2);

 double zconcreteCap = lab_side3over2 + concreteCap_side3over2;
 TGeoRotation *CC_rot = new TGeoRotation("CC_rot",0.0,0.0,0.0);
 TGeoCombiTrans *tlconcreteCap = new TGeoCombiTrans("tlconcreteCap",0.,0.,zconcreteCap,CC_rot);
 tlconcreteCap->RegisterYourself();

 TGeoBBox *OAV_i = new TGeoBBox("OAV_i",outerAirVolume_side1over2,outerAirVolume_side2over2,
                outerAirVolume_side3over2);
 TGeoCombiTrans *adjust1 = new TGeoCombiTrans("adjust1", 0.0,0.0,concreteCap_side3over2, CC_rot);
 adjust1->RegisterYourself();
 TGeoCompositeShape *cs3 = new TGeoCompositeShape("cs3","OAV_i-(CC_i:adjust1)");
 //TGeoVolume *outerAirVolume = new TGeoVolume("outerAirVolume",cs3,airMed);
 ///// make translations to move certain parts
 //double zbucket = 9.2072;
 //double xGArCyl = 0.11013 * 100.;
 //double yGArCyl = 0.030582*100.;
 //double zGArCyl = 0.01016*100.;
 
 TGeoTranslation *tlGArCyl = new TGeoTranslation(xGArCyl, yGArCyl, zGArCyl);
 TGeoTranslation *tlLab = new TGeoTranslation(0.,0.,100.);

 double zCap = GArCyl_heightover2 + steelCap_heightover2;
 TGeoTranslation *tlCap = new TGeoTranslation(xGArCyl,yGArCyl,zCap+zGArCyl);
 double bVshift = -GArCyl_bottomVacuum_heightover2 - 0.3048*100. - (1.23825/2. - 0.3048)*100. + zGArCyl;
 TGeoTranslation *tlbV = new TGeoTranslation(xGArCyl,yGArCyl, bVshift); 
 double bVshift2 = bVshift + bCyl_height - bParab_dz;
 TGeoTranslation *tlbV2 = new TGeoTranslation(xGArCyl,yGArCyl, bVshift2); 
 
 // coord can rotate just about, if not, everything if needed. Rotation of the enitre geometry is done outside this program though. coord would rotate every single thing about its own center, so perhaps not so useful.

 // below is a bunch of rotations and translations. A bit verbose, probably, but this gives lots of freedom for changing things as needed.
 TGeoRotation *coord = new TGeoRotation("coord",0.,0.,0.);
 
 TGeoCombiTrans *cCube = new TGeoCombiTrans("cCube",0.,0.,0.,rCube);
 TGeoCombiTrans *cBucket = new TGeoCombiTrans("cBucket",0.,0.,0.,coord);
 // TGeoCombiTrans *cGArCyl = new TGeoCombiTrans("cGArCyl",xGArCyl,yGArCyl,zGArCyl,coord);
 TGeoCombiTrans *cBucket_steelLayer = new TGeoCombiTrans("cBucket_steelLayer",0.,0.,0.,coord);
 TGeoCombiTrans *cGArCyl_steelLayer1 = new TGeoCombiTrans("cGArCyl_steelLayer1",xGArCyl,yGArCyl,zGArCyl,coord);
 TGeoCombiTrans *cGArCyl_steelLayer2 = new TGeoCombiTrans("cGArCyl_steelLayer2",xGArCyl,yGArCyl,zGArCyl,coord);
 TGeoCombiTrans *cGArCyl_vacuumLayer = new TGeoCombiTrans("cGArCyl_vacuumLayer",xGArCyl,yGArCyl,zGArCyl,coord);
 TGeoCombiTrans *cGArCyl_bottomVacuum_steelLayer = new TGeoCombiTrans("cGArCyl_bottomVacuum_steelLayer",xGArCyl,yGArCyl, bVshift,coord);
 TGeoCombiTrans *csteelCap = new TGeoCombiTrans("csteelCap",xGArCyl,yGArCyl,zCap+zGArCyl,coord);
 TGeoCombiTrans *cconcreteCap = new TGeoCombiTrans("cconcreteCap",0.,0.,zconcreteCap,coord);
 TGeoCombiTrans *clab = new TGeoCombiTrans("clab",0.,0.,0.,coord);
 //TGeoCombiTrans *ccomp = new TGeoCombiTrans("ccomp",xGArCyl,yGArCyl, bVshift,coord);
 TGeoRotation *rotatething = new TGeoRotation("rotatething", 90.,0.,0.);
 TGeoCombiTrans *ccomp2 = new TGeoCombiTrans("ccomp2",0.,0.,bucket_heightover2,rotatething);
 //TGeoCombiTrans *cparab_GAr = new TGeoCombiTrans("cparab_GAr",xGArCyl,yGArCyl, bVshift2,coord);
 TGeoCombiTrans *cbCyl = new TGeoCombiTrans("cbCyl",xGArCyl,yGArCyl, bVshift,coord);

 // define top volume
 TGeoVolume *top = outerAirVolume;
 //TGeoVolume *top = lab;
 
 //bucket->AddNode(LArCube,1,cCube);

 // add daughter volumes to mother volume, apply transformations
 top->AddNode(LArCube,1,cCube);
 top->AddNode(bucket,1);
 top->AddNode(GArCylinder,1);
 top->AddNode(bucket_steelLayer,1, cBucket_steelLayer);
 top->AddNode(GArCyl_steelLayer1,1,cGArCyl_steelLayer1);
 top->AddNode(GArCyl_steelLayer2,1,cGArCyl_steelLayer2);
 top->AddNode(GArCyl_vacuumLayer,1,cGArCyl_vacuumLayer);
 //top->AddNode(GArCyl_bottomVacuum,1,tlbV);
 top->AddNode(GArCyl_bottomVacuum_steelLayer,1,cGArCyl_bottomVacuum_steelLayer);
 top->AddNode(steelCap,1,csteelCap);
 top->AddNode(concreteCap,1,cconcreteCap);
 top->AddNode(lab,1,clab);
 //top->AddNode(comp,1,ccomp);
 top->AddNode(comp2,1,ccomp2);
 //top->AddNode(parab_GAr,1,cparab_GAr);
 top->AddNode(bCyl,1,cbCyl);
 
 gGeoManager->SetTopVolume(top);
 
 gGeoManager->CloseGeometry();
 
 // set colors
 bucket->SetLineColor(kMagenta);
 lab->SetLineColor(kBlack);
 GArCylinder->SetLineColor(kYellow);
 GArCyl_steelLayer1->SetLineColor(kRed);
 GArCyl_steelLayer1->SetLineStyle(kDotted);
 GArCyl_steelLayer2->SetLineColor(kBlue);
 GArCyl_steelLayer2->SetLineStyle(kDotted);
 GArCyl_vacuumLayer->SetLineColor(kMagenta);
 GArCyl_vacuumLayer->SetLineStyle(kDotted);
 //parab_GAr->SetLineColor(kMagenta);
 //parab_GAr->SetLineStyle(kDotted);
 //comp->SetLineColor(kMagenta);
 //comp->SetLineStyle(kDotted);
 steelCap->SetLineColor(kBlue);
 concreteCap->SetLineColor(kOrange);
 outerAirVolume->SetLineColor(kGreen);
 bCyl->SetLineColor(kGreen);

 gGeoManager->SetTopVisible(); // the TOP is invisible
 top->Draw();

 // checks for overlaps
 double precision = 0.001;
 gGeoManager->CheckOverlaps(precision, "d");

 gGeoManager->Export("geometries/SingleCubeTest.gdml");
 gGeoManager->Export("geometries/SingleCubeTest.root");

}
