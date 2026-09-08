function imStack = load2D_OMEROstack(session,ImageID,varargin)

%loads in a movie stored in OMERO for use with integratedTrackGUI

%Get the image properties
image = getImages(session,ImageID);
pixels = image.getPrimaryPixels();
% sizeZ = pixels.getSizeZ().getValue();
sizeT = pixels.getSizeT().getValue();
% sizeC = pixels.getSizeC().getValue();
sizeX = pixels.getSizeX().getValue();
sizeY = pixels.getSizeY().getValue();


for i = 1:sizeT
    if ~isempty(varargin)
        statusHandle = varargin{1};
        statusHandle.Text = ['Reading Image ', num2str(i), ' of ',num2str(sizeT)];
    end
    imStack(i).data = getPlane(session,ImageID,0,0,i-1);
    imStack(i).height = sizeY;
    imStack(i).width = sizeX;
end
