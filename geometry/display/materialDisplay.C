void materialDisplay(TString filename,Bool_t checkoverlaps=kFALSE,TString label="geom-test.root" )
{
  Int_t PriKolor[] = {  2,  3,  4,  5,  6,  7,  8, 9, 28, 30, 38, 40, 41, 42, 46 };
  Int_t PriIndex = 0;
  std::map<TString,Int_t> Kolor;
  Kolor["Air"]        = kWhite;
  Kolor["Copper"]     = kOrange;
  Kolor["DC"]         = kViolet;
  Kolor["EJ280WLS"]   = kSpring;
  Kolor["ESR"]        = kGray;
  Kolor["FR4"]        = kGreen;
  Kolor["GAr"]        = kWhite;
  Kolor["Gold"]       = kOrange;
  Kolor["G10"]        = kTeal;
  Kolor["Kapton"]     = kBlack;
  Kolor["LAr"]        = kAzure;
  Kolor["PVT"]        = kWhite;
  Kolor["SiO2"]       = kBlack;
  Kolor["Steel"]      = kGray;
  Kolor["SSteel304"]  = kGray;
  Kolor["TPB"]        = kSpring;

  TGeoManager *geo2 = new TGeoManager("geo2","test");
	geo2->Import(filename);
  if ( checkoverlaps )
  {
    geo2->CheckOverlaps(1e-5,"d");
    geo2->CheckOverlaps(1e-5,"s10000000");
		geo2->PrintOverlaps();
  }
  geo2->SetVisLevel(20);
  TGeoVolume *volume = NULL;
  TObjArray *volumes = geo2->GetListOfVolumes();
  Int_t nvolumes = volumes->GetEntries();
  for ( int i = 0; i < nvolumes; i++ )
  {
    volume = (TGeoVolume*)volumes->At(i);
    volume->SetVisContainers(kTRUE);
    if ( TString(volume->GetName()).Contains("DetEnclosure"))
    {
      volume->SetVisibility(kFALSE);
      continue;
    }
    if ( TString(volume->GetMaterial()->GetName()).Contains("Air"))
    {
      volume->SetVisibility(kFALSE);
      continue;
    }
    Int_t daughters = volume->GetNdaughters();
		cout << volume->GetName() << " NDaughters = " << volume->GetMaterial()->GetName() << " " << daughters << endl;
    volume->SetLineColor(Kolor[volume->GetMaterial()->GetName()]);
    switch ( daughters )
    {
      case 0: volume->SetTransparency(100);
      case 1: volume->SetTransparency(80);
      case 2: volume->SetTransparency(60);
      case 3: volume->SetTransparency(40);
      default: volume->SetTransparency(10);
    }

  }
	geo2->Export(label);
  geo2->GetTopVolume()->Draw("ogl");
  //geo2->Export("/dune/data/users/sfogarty/DUNE-Geometries/testing/SingleCube.root");
}
