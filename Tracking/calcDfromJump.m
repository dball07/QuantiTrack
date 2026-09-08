function maxD = calcDfromJump(maxJump,px_size,frameTime,sigmas)

maxD = ((maxJump.*px_size).^2)./((sigmas.^2)*frameTime);

