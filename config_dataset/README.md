# Config_dataset

This folder performs two main functions.
1) Allow user to download the reconstructed / reorganized LPM dataset
2) Allow user to add new videos to the dataset

# Downloading the reconstructed dataset

Run 'download_final.py' to allow downloads from Google Drive.
'dataset.tar.gz' file will be downloaded to your local directory.
Note that the file is very large, and download requires SNU email login.

This dataset is reconstructed from the LPM Dataset, with all the lecture videos mentioned in raw_video_links.csv provided from the original authors. Note that, the dataset is reorganized into the scheme we need - datas about the ocr, timestamp per word, mouse traces and such are eliminated, as they are unnecessary to our model.

# Adding new files to the dataset

1) Execute add_new_video.py
- This python script enables GUI that allows the user to add new youtube video links, which will then be downloaded to user local.
- The video will then be played on the GUI, allowing the user to make timestamps of the desired lecture slide by clicking on the corresponding button
- The timestamps are visible to the bottom of the GUI, and user may undo unwanted timestamps
- Once the 'stamping' is finished for the entire video, user may write to the raw_video_links.csv, to which the script ('extract_slide_imgs_from_youtube.py', 'make_left_video_links.py') works on to extract slide images.
- GUI allows the user to remove the video from local computer with a single push of a button.

2) Execute 'extract_slide_imgs_from_youtube.py' to extract slide images from the extracted timestamp.

3) Execute 'make_left_video_links.py' if the download is aborted by Youtube restrictions etc. then resume downloading with 'extract_slide_imgs_from_youtube.py'. Repeat until the download is complete.

4) Execute ASR.py, which utilizes GoogleASR to take audio transcripts from the desired video.
- This script belongs to https://github.com/dondongwon/LPMDataset/preprocessing , the original authors of LPM Dataset.
