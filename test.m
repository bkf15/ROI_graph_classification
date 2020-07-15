%right now, this is just moving slide images into format so segmentation
%code can read them
slide_im_dirs = dir('all_slides');
slide_im_dirs = slide_im_dirs(3:end);

segmentation_path = '..\Cell-Nuclei-Detection-and-Segmentation\slides_for_segmentation';

warning('off');

for i = 1:size(slide_im_dirs, 1)
    case_dir = dir(strcat(slide_im_dirs(i).folder, "\",  slide_im_dirs(i).name));
    case_dir = case_dir(3:end);
    for j = 1:size(case_dir, 1)
       im_name = case_dir(j).name; 
       %remove .jpg 
       im_name = im_name(1:end-4);
       %read actual image
       im = imread(strcat(case_dir(j).folder, "\", case_dir(j).name)); 
       %save to segmentation code folder
       parent_path = "C:\Users\Brian\Desktop\AIProject\Cell-Nuclei-Detection-and-Segmentation\slides_for_segmentation"; 
       mkdir(parent_path, im_name);
       imwrite(im, strcat(parent_path, "\", im_name, "\", im_name, ".jpg"));
    end
end