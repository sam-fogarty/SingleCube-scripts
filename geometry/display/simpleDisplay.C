void simpleDisplay(TString filename)
{

  TGeoManager *geo = new TGeoManager();
  geo->Import(filename);
  geo->GetTopVolume()->Draw("ogl");
  
  TGLSAViewer *glsa = (TGLSAViewer *)gPad->GetViewer3D();
  glsa->DrawGuides();
  glsa->UpdateScene();
  


}
