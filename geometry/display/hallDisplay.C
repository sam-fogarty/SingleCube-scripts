void hallDisplay(TString filename, Int_t VisLevel=5)
{
	TGeoManager *geo = new TGeoManager();
	geo->Import(filename);
	geo->DefaultColors();


	geo->CheckOverlaps(1e-5,"d");
 	geo->PrintOverlaps();
	geo->SetVisOption(1);
	geo->SetVisLevel(VisLevel);

	// 521 is a rootino
	int pdg=14;
	int m1=0; int m2=0; int d1=0; int d2=0;
	double p=1.0;
	double beam_angle=0.101;
	double py=-p*sin(beam_angle);
	double pz= p*cos(beam_angle);
	double px=0;
	double vx=0;
	double vz=-762; //Front of hall at -762 in global coordinate system
	double hall_start_z_in_hall_coordinates=-15.02e2;// ~15m
	double hall_length=-2*hall_start_z_in_hall_coordinates;
	double hall_back_global=-762 + hall_length;
	double beam_entering_height=592.2 - hall_start_z_in_hall_coordinates*tan(0.101);
	double global_y0_height=335;
	double vy=beam_entering_height-global_y0_height;
	cout<<"Beam enters the hall at a height of "<<beam_entering_height<<" cm"<<endl;
	cout<<"That is y= "<<vy<<" in the global coordinate system"<<endl;
	TParticle* beam_particle = new TParticle(521,1,m1,m2,d1,d2,px,py,pz,p, vx,vy,vz,0);
	Int_t track_index = geo->AddTrack(0,pdg,beam_particle);
	TVirtualGeoTrack* beam_track = geo->GetTrack(track_index);
	int npoints=100;
	double step=hall_length/(1.0*npoints);
	double linex[npoints];
	double liney[npoints];
	double linez[npoints];
	for (int ipoint=0; ipoint<npoints; ipoint++){
	  double dz=step*ipoint;
	  double dy=-dz*tan(beam_angle);
	  double z=vz+dz;
	  double y=vy+dy;
	  cout<<"point "<<ipoint<<" : z= "<<z<<" y= "<<y<<endl;
	  beam_track->AddPoint(0,y,z,5e-9);
	  linex[ipoint]=0;
	  liney[ipoint]=y;
	  linez[ipoint]=z;
	}
	TPolyLine3D* beam_line= new TPolyLine3D(npoints,linex,liney,linez);

	gGeoManager->GetListOfVolumes()->ls();
	// TGeoVolume* active =gGeoManager->GetVolume("volLArActive");
	
	// get argon cube active volume coordinates
	//	gGeoManager->cd("/volWorld_1/volDetEnclosure_0/volArgonCubeDetector_0/volLArCryo_0/volArgonCube_0/volArgonCubeActive_0");

	const char* lar_active_location="/volWorld_1/volDetEnclosure_0/volArgonCubeDetector_0/volArgonCubeCryostat_0/volReinforcedConcrete_0/volMoistureBarrier_0/volInsulationBoard2_0/volGREBoard2_0/volInsulationBoard1_0/volGREBoard1_0/volFireproofBoard_0/volSSMembrane_0/volArgonCubeService_0/volArgonCube_0/volArgonCubeActive_0";
	gGeoManager->cd(lar_active_location);
	TGeoMatrix *active = gGeoManager->GetCurrentMatrix();
	double local_active[3]={0,0,0};
	double master_active[3]={0,0,0};	
	active->LocalToMaster(local_active,master_active);
	cout<<"The center of ArgonCubeActive in the global coordinate system: \n"<<" ( "<<master_active[0]<<", "<<master_active[1]<<", "<<master_active[2]<<" )"<<endl;

	// get detector enclosure coordinates
	gGeoManager->cd("/volWorld_1/volDetEnclosure_0");
	TGeoMatrix *enclosure = gGeoManager->GetCurrentMatrix();
	double local_enclosure[3]={0,0,0};
	double master_enclosure[3]={0,0,0};	
	enclosure->LocalToMaster(local_enclosure,master_enclosure);
	cout<<"The center of DetEnclosure in the global coordinate system: \n"<<" ( "<<master_enclosure[0]<<", "<<master_enclosure[1]<<", "<<master_enclosure[2]<<" )"<<endl;

	// print location of LArTPC in the detector enclosure
	double active_in_enclosure[3]={0,0,0};
	enclosure->MasterToLocal(master_active,active_in_enclosure);

	cout<<"The center of ArgonCubeActive in the DetEnclosure coordinate system: \n"<<" ( "<<active_in_enclosure[0]<<", "<<active_in_enclosure[1]<<", "<<active_in_enclosure[2]<<" )"<<endl;
	
	// print out location of GArTPC
	gGeoManager->cd("/volWorld_1/volDetEnclosure_0/volCylindricalMPT_0/volGArTPC_0");
	TGeoMatrix *gartpc = gGeoManager->GetCurrentMatrix();
	double local_gartpc[3]={0,0,0};
	double master_gartpc[3]={0,0,0};	
	gartpc->LocalToMaster(local_gartpc,master_gartpc);
	cout<<"The center of GArTPC in the global coordinate system: \n"<<" ( "<<master_gartpc[0]<<", "<<master_gartpc[1]<<", "<<master_gartpc[2]<<" )"<<endl;	

	double gartpc_in_enclosure[3]={0,0,0};
	enclosure->MasterToLocal(master_gartpc,gartpc_in_enclosure);

	cout<<"The center of GArTPC in the DetEnclosure coordinate system: \n"<<" ( "<<gartpc_in_enclosure[0]<<", "<<gartpc_in_enclosure[1]<<", "<<gartpc_in_enclosure[2]<<" )"<<endl;


	geo->GetTopVolume()->Draw("ogl");
	//	geo->DrawTracks("ogl");
	beam_line->SetLineWidth(2);
	beam_line->SetLineColor(kRed);
	beam_line->SetLineStyle(kDashed);
	beam_line->Draw();

	TGeoVolume* enc=geo->GetVolume("volDetEnclosure");
	enc->SetVisibility(kFALSE);
	enc->VisibleDaughters(kTRUE);
	TGeoVolume* ar3=geo->GetVolume("volArgonCubeDetector");
	ar3->SetTransparency(50);
	ar3->SetVisContainers(kTRUE);
	ar3->VisibleDaughters(kTRUE);
	TGeoVolume* cryo=geo->GetVolume("volArgonCubeCryostat");
	cryo->SetTransparency(50);
	cryo->SetVisContainers(kTRUE);
	cryo->VisibleDaughters(kTRUE);
	for(int iwall=0; iwall<35; iwall++){
	  TGeoVolume* wall=geo->GetVolume(Form("volLArActiveModWall%02i",iwall));
	  if(wall) wall->SetTransparency(80);
	}
	TGeoVolume* cent_elec=geo->GetVolume("cent_elec_vol");
	cent_elec->SetTransparency(90);
	//	cout<<"cent_elec "<<cent_elec<<endl;


	TGLSAViewer *glsa = (TGLSAViewer *)gPad->GetViewer3D();
	TGLClipSet* clip =glsa->GetClipSet();
	// components - A,B,C,D - of plane eq : Ax+By+CZ+D = 0 
	// kClipPlane=1
	Double_t clip_config[6]={-1,0,0,-0.5,0,0};
	//	clip->SetShowClip(kTRUE);
	clip->SetAutoUpdate(kTRUE);
	clip->SetClipState(TGLClip::EType::kClipPlane,clip_config);
	clip->SetClipType(TGLClip::EType::kClipPlane);
	glsa->DrawGuides();
	glsa->UpdateScene();

	//	TGCompositeFrame* frame = glsa->GetFrame();
}
