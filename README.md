## A Magisk module for preventing clipping and saturation distortion around 0dB peaks when using bluetooth audio devices

This module has been developed for avoiding digital distortions when using the absolute volume of bluetooth devices, because it was forced by removing "Disable Absolute Volume" toggle switch in the developer settings on Android 17. One of the distortions is made by clipping when encoding audio data around 0dB into any codec, and the other is made by saturation (dynamic range compression) near 0dB when encoding the data into high resolution codecs, especially for higher quality modes increasing the cut-off frequency of a low-pass filter so as to include higher harmonics and background details.

The method used in this module modifies the audio policy volume curve for bluetooth earphones (and wired ones, but except USB ones) of the system-wide mixer (AudioFlinger) in 24 or 32 bit depth to prevent clipping, while avoiding "bit truncation" in 16 bit audio data sent from a music app for high resolution bluetooth codecs (in 24 and 32 bit modes, e.g., LDAC and aptX HD). Because the mixer sends audio data to bluetooth codec encoders at the maximum output gain defined in the curve (not 0dB output gain) if the bluetooth absolute volume is used.

## DISCLAIMER

* I am not responsible for any damage that may occur to your devices, so it is your own choice whether to attempt this module or not.

##
