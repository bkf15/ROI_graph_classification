%code for generating and saving graphs for whole ROI's
addpath(pwd + "/AOFSkeletons_Code");
addpath(pwd + "/find_skel_intersection");

%fetch labels for miccai dataset
labels = get_labels();

%distance threshold to draw edges (in euclidean pixels)
dist_threshold = 50;
%cosine similarity threshold to draw edges in similarity graph
sim_threshold = 0.977;
compute_sim_edges = false;      %whether or not to compute the similarity graph

%get the files of all the images
images = dir('all_slides/*/*.jpg');

%filter images, only keep ones with labels
labeled_im_names = labels.slide_names;
labeled_inds = [];
for i = 1:size(images,1)
    %k will be in index in labeled_im_names which has the same name as
    %images(i)
    k = find(strcmp(labeled_im_names, images(i).name));
    if k
       labeled_inds(end+1) = i;
       images(i).p1_label = labels.p1_labels(k);
       images(i).p2_label = labels.p2_labels(k);
       images(i).p3_label = labels.p3_labels(k);
    end
end
images = images(labeled_inds);

roi_data = struct('image', {}, 'label', {}, 'nuclei_features', {}, 'graph', {});

%loop over the images
tic
for i = 1:size(images, 1)
    im_name = images(i).name;
    slide_im = imread(strcat(images(i).folder, "\", images(i).name));
    %now search ground truth labels to see if we have a label for this
    %image, otherwise just dont use the image 
    %if isempty(find(contains(labels.slide_names, im_name), 1))
    %   continue; 
    %end
    
    %now, find the associated cell segmentation (already computed)
    
    %or, compute the nuclei segmentation on the fly
    %   PCA works for now, not as smooth of a segmentation, but much much
    %   faster
    nuclei_boundaries = PCA_nuclei_segmentation(slide_im);
    %smooth boundaries
    
    %figure; imshow(imoverlay(slide_im, nuclei_boundaries));
    
    %generate graph of nuclei
    nuclei_cc = bwconncomp(nuclei_boundaries);
    %nodes are spatially located via the centroid of the cc
    %   note that 'centroid' returns them in [col row] order
    centers = regionprops(nuclei_cc, 'centroid');
    nodes = [];  %[node_id centroid_row centroid_col]
    X = [];     %node features, X{i} = features for nodes[i]
    for j=1:nuclei_cc.NumObjects
        %make temp image with only this nuclei
        t = zeros(size(nuclei_boundaries));
        t(nuclei_cc.PixelIdxList{j}) = 1;
        %extract features
        feat = get_morphological_features(t);
        feat_names = fieldnames(feat);
        nodes = [nodes; j-1 centers(j).Centroid(2) centers(j).Centroid(1)]; %putting back in [row col]
        X = [X; cell2mat(struct2cell(feat))'];
    end
    %now, draw edges between nodes based on a distance criteria 
    edges = [];
    for j = 1:size(nodes, 1)
       for k = j+1:size(nodes, 1)
          if sqrt((nodes(j,2) - nodes(k,2))^2 + (nodes(j,3) - nodes(k,3))^2) <= dist_threshold
              edges = [edges, [nodes(j,1) ; nodes(k,1)]];
              %needs to be symmetric, so its not seen as directional
              edges = [edges, [nodes(k,1) ; nodes(j,1)]];
          end
       end
    end
    
    %now, draw edges between nodes based on similarity criteria
    sim_edges = [];
    similarities = [];
    if compute_sim_edges
    for j = 1:size(nodes, 1)
       for k = j+1:size(nodes, 1)
          %compute cosine similarity
          similarity = dot(X(nodes(j,1)+1,:),X(nodes(k,1)+1,:)) / ... 
              (norm(X(nodes(j,1)+1,:)) * norm(X(nodes(k,1)+1,:)));
          similarities(end+1) = similarity;
          if similarity >= sim_threshold
              sim_edges = [sim_edges, [nodes(j,1) ; nodes(k,1)]];
              %needs to be symmetric, so its not seen as directional
              sim_edges = [sim_edges, [nodes(k,1) ; nodes(j,1)]];
          end
       end
    end
    %plot distribution of similarities
    figure; histfit(similarities);
    end

    visualize = false;
    %visualize the graph over the image
    if visualize
       figure; imshow(slide_im); hold on;
       for j = 1:size(nodes, 1)
          plot(nodes(j,3), nodes(j,2), 'ro');
       end
       for j = 1:size(edges, 2)
          plot([nodes(edges(1, j)+1, 3), nodes(edges(2, j)+1, 3)], ...
              [nodes(edges(1, j)+1, 2), nodes(edges(2, j)+1, 2)], 'r-');
       end
       title(sprintf("Distance graph for dist threshold=%d", dist_threshold));
    end
   
    %save as json with edge connections and node features 
    obj = struct("name", im_name, "node_features", X, "dist_edge_table", edges, ...
        "labels", struct("p1_label", images(i).p1_label, "p2_label", images(i).p2_label, ...
        "p3_label", images(i).p3_label));
    json_text = jsonencode(obj);
    fname = im_name(1:end-4);
    fid = fopen(sprintf("C:\\Users\\Brian\\Desktop\\AIProject\\roi_graph_jsons\\%s.json",fname),"w");
    if fid == -1, error("Error, cannot create json file"); end
    fprintf(fid, json_text, 'char');
    fclose(fid);
    fprintf("Image %d of %d...\tTotal ", i, size(images,1));
    toc
end