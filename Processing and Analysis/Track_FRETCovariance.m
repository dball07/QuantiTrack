function trk_cov = Track_FRETCovariance(Results,imStack)


Sec_trks = AddAiryIntensity(Results.Tracking.Tracks,Results.Parameters.Acquisition.pixelSize,imStack);

trk_cov(:,1) = Results.PreAnalysis.Tracks_um(:,6) - Results.PreAnalysis.Tracks_um(:,7);
trk_cov(:,2) = Sec_trks(:,6) - Sec_trks(:,7);
trk_cov(:,3) = Results.PreAnalysis.Tracks_um(:,4); %TrackID
trk_cov(:,4) = Results.PreAnalysis.Tracks_um(:,3); %Frame num

