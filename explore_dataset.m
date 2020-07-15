%fetch labels for miccai dataset
labels = get_labels();
full_concordance = 0; %417
full_concordance_inds = [];
partial_concordance = 0; %893
partial_concordance_inds = [];
no_concordance = 452; %452
no_concordance_inds = [];

total_labels = [0 0 0 0] %normal CCC fea ADH

for i=1:size(labels.p1_labels, 1)
   if strcmpi(labels.p1_labels(i), labels.p2_labels(i)) && ...
       strcmpi(labels.p1_labels(i), labels.p3_labels(i))
       full_concordance = full_concordance + 1;
       full_concordance_inds = [full_concordance_inds i];
       continue;
   
   elseif strcmpi(labels.p1_labels(i), labels.p2_labels(i)) || ...
       strcmpi(labels.p1_labels(i), labels.p3_labels(i)) || ...
       strcmpi(labels.p2_labels(i), labels.p3_labels(i))
       partial_concordance = partial_concordance + 1;
       partial_concordance_inds = [partial_concordance_inds i];
   
   else
      no_concordance_inds = [no_concordance_inds i]; 
   end
end

p1_labels = labels.p1_labels;
p1_labels = p1_labels(full_concordance_inds);
p1_labels = p1_labels(1:end-4);

a = categorical(p1_labels);
figure; histogram(a); title('Full Concordance Labels', 'fontsize', 26);
ylabel("Number of samples", 'fontsize', 20);
set(gca, 'fontsize', 20);

p1_labels = labels.p1_labels;
p1_labels = p1_labels(partial_concordance_inds);
p1_labels = p1_labels(1:end-4);

a = categorical(p1_labels);
figure; histogram(a); title('Partial Concordance Labels', 'fontsize', 26);
ylabel("Number of samples", 'fontsize', 20);
set(gca, 'fontsize', 20);


p1_labels = labels.p1_labels;
p1_labels = p1_labels(no_concordance_inds);
p1_labels = p1_labels(1:end-4);

a = categorical(p1_labels);
figure; histogram(a); title('No Concordance Labels','fontsize', 26);
ylabel("Number of samples", 'fontsize', 20);
set(gca, 'fontsize', 20);


p1_labels(p1_labels=="ADH") = "High-Risk";
p1_labels(p1_labels=="Flat Epithelial") = "High-Risk";
p1_labels(p1_labels=="Columnar") = "Low-risk";
p1_labels(p1_labels=="Normal Duct") = "Low-risk";

%a = categorical(p1_labels);
%figure; histogram(a); title('Labeled Dataset Histogram');

X = categorical({'Full', 'Partial', 'None'});
X = reordercats(X,{'Full', 'Partial', 'None'});
figure; bar(X,[full_concordance partial_concordance no_concordance]);
ylabel("Number of samples",'fontsize', 20);
title("Label consistency",'fontsize', 26);
set(gca, 'fontsize', 20);