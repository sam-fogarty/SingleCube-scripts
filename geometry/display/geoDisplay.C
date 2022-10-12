void geoDisplay(TString filename, Int_t VisLevel=5)
{
	TGeoManager *geo = new TGeoManager();
	//fTopNode = 10.0;
	TGeoMaterial *mat = new TGeoMaterial("Al", 26.98,13,2.7);
	TGeoMedium *med = new TGeoMedium("MED",1,mat);
	TGeoVolume *top = gGeoManager->MakeBox("TOP",med,100,100,100);
	gGeoManager->SetTopVolume(top);
        gGeoManager->CloseGeometry();
        
	geo->Import(filename);
        
	//geo->DefaultColors();


	//geo->CheckOverlaps(1e-5,"d");
        //geo->CheckOverlaps(1e-5);
 	//geo->PrintOverlaps();
	//geo->SetVisOption(1);
	geo->SetVisLevel(VisLevel);
	//geo->GetTopVolume()->Print();
	//geo->GetTopVolume()->Draw("ogl");
	
	TGLViewer * v = (TGLViewer *)gPad->GetViewer3D();
	v->SetStyle(TGLRnrCtx::kOutline);
	v->SetSmoothPoints(kTRUE);
	v->SetLineScale(0.5);
	//	v->UseDarkColorSet();
	v->UpdateScene();
}
