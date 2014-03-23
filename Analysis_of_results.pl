use Cwd;
use IO::Handle;
use File::Copy;
use LWP::Simple;
use Archive::Tar;
#use File::Find::Rule;
#use LWP::UserAgent;

$pwd = getcwd() ;
@p2 = split('/' , $pwd) ;
pop(@p2) ;
$parent = join( '/', @p2) ; #this is the parent file

$num_args = $#ARGV + 1;
if ($num_args != 3) {
  print "\nError. Usage: Analysis.pl extreme_file_name mcl_directory_name miss_rate\n";
  print "Note that each of MCL files should be in a separate folder. ex: MCL_Data/inflation2/MCL_2_result.txt\n" ;
  exit;
}

$ES_file=$ARGV[0];
$MCL_Directory=$ARGV[1];
$miss = $ARGV[2];
$original_miss = $miss ;
$number_es = $ES_file ;
$number_es =~ s/ES_//g ; 
$number_mcl = $MCL_Directory ;
$number_mcl =~ s/MCL_//g ; 

$url = 'http://archive.geneontology.org/latest-termdb/';
$file_go_obo = 'go_daily-termdb.obo-xml.gz';
$status = getstore($url, $file_go_obo);



$result_directory = $pwd."/Analysis_result_".$miss ; #This is the result directory
unless(-d $result_directory){ mkdir $result_directory or die $! ;}
$matlab_files = $result_directory."/Matlab_Files" ;
unless(-d $matlab_files){ mkdir $matlab_files or die $! ;}

$dir_files = $pwd."/Files_needed" ;

#&Download_go_daily;
&Fix_Extreme_set ;
&Create_ES;
&Create_MCL ;
&Copy_Files ;
&Missing_Generator ;
&GS2_Generator;
&Find_Neighbor ;
&Find_Known_groups;
&Prediction_Using_All ;
&Prediction_Using_Only_Neighbors ;
&Compare_predictions("Y"); 
&Compare_predictions("N") ;
&Clusters_of_difference("Y"); 
&Clusters_of_difference("N"); 
&How_Correct("Y");
&How_Correct("N");
&Clusters_sizes("Y");
&Clusters_sizes("N");
&Matlab_gs2 ;
&Get_Sizes_MATLAB ;
&Size_Avg_Accuracy;
&Cleaning_files;




################################################################################################
sub Download_go_daily {
    chdir("Files_needed") ;
    my $url = 'http://archive.geneontology.org/latest-termdb/';
    my $file_go_obo = 'go_daily-termdb.obo-xml.gz';
    $status = getstore($url, $file_go_obo);
    #die "Error $status on $url" unless is_success($status);
    # system "gzip -d go_daily-termdb.obo-xml.gz" ;
    #unlink("$dir_files/go_daily-termdb.obo-xml.gz") ;
    print "Downloaded go_daily-termdb.obo-xml.gz and extracted.\t".(localtime),"\n"; ;

}
################################################################################################
sub Fix_Extreme_set{
    open (IN_ES, "<$ES_file") or die $!; #this should be the file of extreme set results
    open (OUT2, ">$result_directory/test_$ES_file.txt") or die $!;
    
    %hash = ();
    %hash2 = ();
    $line = <IN_ES>; 
    $line_number =1 ;
    while ($line) {
        chomp $line ;
        @arr_line = split ("_",$line) ;
        $size = @arr_line ;
        $value = join( "\t", @arr_line) ;
        $hash{$line_number} = $size ;
        $hash2{$line_number} = $value ;
        undef @arr_line ;
        $line = <IN_ES>;
        $line_number++;
    }

    $i=$line_number-1 ;
    foreach $key (reverse sort { $hash{$b} <=> $hash{$a} } keys %hash){
        print OUT2 "$i\t$hash2{$key}\n" ;
        
        if ($i==0){
            print "An Error has occured.key is $key and $i\n" ;
        }
        $i-- ;
    }
    OUT2->flush();

    

    undef %hash ;
    undef %hash2 ;
    undef $sub_element ;
    close(OUT2) ;
    #Now I have the test file for tabbed version. Now I need to change it to not be hierarchical anymore.
    open (in_tab, "<$result_directory/test_$ES_file.txt") or die $!;
    %hash_tab = ();
    %hash_value = ();
    %hash_size=() ;
    $line = <in_tab>;
    while ($line){
        chomp $line;
        $string = "";
        ($name, @elements) = split("\t", $line);
        $size = @elements ;
        $hash_size{$name} = $size;
        foreach $member (@elements) {
            if (!(defined $hash_tab{$member})) {
                $hash_tab{$member} = $name ;    
                $string = $string."\t".$member;
            }
            else{
                $hash_size{$name} = $hash_size{$name} -1 ;
            }
        }
        $hash_value{$name} = $string ;
        $line = <in_tab>;
    }

    open (OUT, ">$result_directory/tabbed_numbered_$ES_file.txt") or die $!;
    $counter = 1 ;
    $singletons =0 ;
    foreach $key (reverse sort {$hash_size{$a} <=> $hash_size{$b}} keys %hash_size){
        @temp_arr=split("\t", $hash_value{$key}) ;
        $size_temp_arr = @temp_arr ;
        if ($size_temp_arr>2){
            print OUT "ES_$counter$hash_value{$key}\n" ;    
            $counter++;
        }
        else {
            $singletons++;
        }
        
    }
    print ".......There were $singletons singletons removed because of not having hierarchy\n" ;

    unlink("$result_directory/test_$ES_file.txt") ;
    if(-e $fix_predict_file) { print "File test_$ES_file.txt still exists!"; }
    print "Extreme sets are now  sorted, tabbed and fixed so that no longer are hierarchical.\t".(localtime),"\n"; ;
}
################################################################################################
sub Create_ES {
    open (IN_ES, "<$result_directory/tabbed_numbered_$ES_file.txt") or die $!;
    $newdirr = "$result_directory/Separate_ES_files_".$number_es ;
    unless(-d $newdirr){ mkdir $newdirr or die $! ;}

    %hash = ();
    $line = <IN_ES>; 
    while ($line) {
     	chomp $line ;
     	($name,@arr_line) = split ("\t",$line) ;
        $value = join( "\n", @arr_line) ;
        $hash{$name} = $value ;
        undef @arr_line ;
     	$line = <IN_ES>;
    }

    foreach $key (keys %hash){
        open (ES_FILES, "> $newdirr/$key") or die $!;
        print ES_FILES "$hash{$key}" ;
    }

    close(ES_FILES) ;
    undef %hash ;
    close(ES_FILES) ;
    close(IN_ES) ;
    print "ES files are separated.\t".(localtime),"\n"; ;
}

################################################################################################
sub Create_MCL {
    #print "Directory is: $MCL_Directory\n\n" ;
    
    my @path_files = <$MCL_Directory/*>;
    $path = $result_directory."/". $MCL_Directory ; 
    unless(-d $path){mkdir $path or die $! ;}
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        $FILENAME = "MCL_".$filee."_".$number_mcl.".txt" ;
        $mcl_dir_result = $path."/".$filee ;
        unless(-d $mcl_dir_result){ mkdir $mcl_dir_result or die $! ;}
        $outname = $path."/".$filee."/numbered_".$FILENAME ;
        open (IN_MCL, "< $MCL_Directory/$filee/$FILENAME") or die $!; 
        open (OUT_MCL, "> $outname") or die $! ;
        
        $dirr = $path."/".$filee."/Separate_MCL_files_".$number_mcl ; 
        unless(-d $dirr){ mkdir $dirr or die $! ; }
        
        $i=1 ;
        $line = <IN_MCL>; 
        while ($line) {
            chomp $line ;
            print OUT_MCL "MCL_$i\t$line\n"  ;
            $file_MCL = "MCL_".$i ;
            open (MCL_FILES, "> $path/$filee/Separate_MCL_files_$number_mcl/$file_MCL") or die $!;
            @array = split ("\t",$line) ;
            foreach $element (@array) {
                $hash_mcl{$element} =1 ;
                print MCL_FILES "$element\n" ;
            }
            undef @array ;
            close(MCL_FILES) ;
            $line = <IN_MCL>;
            $i++ ;
        }

        close(OUT_MCL);
        undef %hash_mcl ;
    }

    undef $filee;

    undef $path ;
    close(IN_MCL) ;
    close(OUT_MCL) ;
    close(MCL_FILES) ;
    print "MCL files are sorted, tabbed and separated.\t".(localtime),"\n"; ;
}
################################################################################################

sub Copy_Files {

    copy("$dir_files/Orig_pyGS2.py",$result_directory) or die "Failed to copy Orig_pyGS2.py $!\n";
    copy("$dir_files/go_daily-termdb.obo-xml",$result_directory) or die "Failed to copy go_daily-termdb.obo-xml $!\n";
    copy("$dir_files/Halophiles_id_GOs.txt",$result_directory) or die "Failed to copy Halophiles_id_GOs.txt $!\n";
    copy("$dir_files/1_print_out_neighbors.py",$result_directory) or die "Failed to copy 1_print_out_neighbors.py $!\n";
    
    print "All copies are done and files are generated.\t".(localtime),"\n"; ;
}
################################################################################################
sub Missing_Generator {
    $path1 = $result_directory."/6a_".$number_es."_gs2" ;   
    open(orig,"<$dir_files/Halophiles_id_GOs.txt") or die $! ;
    $line = <orig> ;
    while($line) {
        chomp $line; 
        ($name, @k) = split ("\t", $line)   ;
        $info = join ("\t", @k) ;
        $hash{$name} = $info ;
        $line = <orig> ;
    }
    close(orig) ;
    $all_go = keys (%hash);
    print ".......There are $all_go halophiles ids\n" ;
    $flag =1 ;
    #$miss = 4 ;

    while ($flag) {
        print ".......File for $miss % miss rate is generated \n" ;
        $str = $result_directory."/".$miss."_removed_Halophiles_id_GOs.txt" ;
        open (out, ">$str") or die $! ;
        $mode = int ($all_go / $miss) ;
        for ($i=1; $i <= $mode ; $i++) {
            $kilid = (keys %hash)[rand keys %hash];
            print out "$kilid\t$hash{$kilid}\n" ; 
        }
        out->flush();
        close (out) ;
        $miss = $miss - 1;
        if ($miss < $original_miss){   #I am only looking at 5% miss rate. This should be 1 if I want all 1-5 miss rates.
            $flag = 0 ;
        }
    }
    close(orig);
    undef %hash ;

    print "Missing files are generated.\t".(localtime),"\n"; ;
}
################################################################################################
sub GS2_Generator {

    %hash=() ;
    $path2 = $result_directory."/MCL_".$number_mcl ; 

    my $dir2 = $result_directory."/Separate_ES_files_".$number_es;
    my @files2 = <$dir2/*>;
    my $count2 = @files2;
    undef @files2 ;
    $ES_num_files= $count2 ; #note that they start from 0 
    
    #print "what is the percentage of missing data?\n" ;

    $some = $result_directory."/".$original_miss."_removed_Halophiles_id_GOs.txt" ;
    print ".......Looking at $original_miss % missing data to generate GS2.\n" ;
    open (GO_FILES, "<$some") or die $!; 
    $line_GO=<GO_FILES> ;
    $comma = ',' ;
    while ($line_GO) {
        chomp $line_GO ;
        ($name,@Go)= split ("\t",$line_GO) ;
        $line_GO =~ s/$name\t//g ;
        $line_GO =~ s/\t/,/g ;
        $GO_info = $line_GO ;
        if (defined $hash{$name}) {
            if (!($hash{$name} eq $GO_info)){
                foreach $element (@Go) {
                    $string_comma = $comma.$element ;
                    $hash{$name} =~ s/$string_comma//g ;
                }   
            $hash{$name} = $hash{$name}.",".$GO_info;   
            }
        }
        else{
                $hash{$name} = $GO_info ;
            }
    $line_GO=<GO_FILES> ;
    }
    close(GO_FILES) ;


    $path_MCL = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path_MCL/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        $dirr2 = $path_MCL."/".$filee ;
        unless(-d $dirr2){ mkdir $dirr2 or die $! ; }
        copy("$dir_files/Orig_pyGS2.py",$dirr2) or die "Failed to copy Orig_pyGS2.py: $!\n";
        copy("$dir_files/go_daily-termdb.obo-xml",$dirr2) or die "Failed to copy go_daily-termdb.obo-xml: $!\n";
        open (OUT, "> $path_MCL/$filee/GS2_MCL_data.py") or die $!;
        open (OUT2, "> $result_directory/GS2_ES_data.py") or die $! ;
        print OUT "from Orig_pyGS2 import get_go_graph \ntree = get_go_graph(open('go_daily-termdb.obo-xml'))\n\n" ;
        print OUT2 "from Orig_pyGS2 import get_go_graph \ntree = get_go_graph(open('go_daily-termdb.obo-xml'))\n\n" ;

        my $dir_sep_mcl = $dirr2."/Separate_MCL_files_".$number_mcl;
        my @files = <$dir_sep_mcl/*>;
        my $count = @files;
        undef @files ;
        $MCL_num_files= $count ; #note that they start from 0 

        $i = $j = 1 ;
        #create a matching table in which each row is a MCL cluster and each column is a ES cluster. the element in this matrix is Mij which 
        for ($i ; $i <=$MCL_num_files ; $i++) {
            $file_MCL = "MCL_". $i ;        #get MCL cluster, lets say mcl_j
            open (MCL_FILES, "< $dir_sep_mcl/$file_MCL") or die $!; 
            $line_mcl = <MCL_FILES>;
            while ($line_mcl) {
                chomp $line_mcl ;
                $line_mcl = "GO_". $line_mcl ;
                print OUT "$line_mcl=[$hash{$line_mcl}]\n" ;
                if (defined ($hash{$line_mcl})) {
                    $temp_mcl_str = $line_mcl.",".$temp_mcl_str; 
                }
            $line_mcl = <MCL_FILES>;
            }
            chop $temp_mcl_str ;
            $sim_mcl = "sim_".$file_MCL ;
            if (!($temp_mcl_str eq '')) {
                if ($temp_mcl_str =~ m /,/) {
                    print OUT "$sim_mcl= tree.GS2([$temp_mcl_str])\n" ; 
                }
                else {
                    print OUT "$sim_mcl=\"One_FOUND\"\n" ; } 
                }
            else {
                print OUT "$sim_mcl=\"NOT_FOUND\"\n" ; 
            }
            #$data = "data"."_".$file_MCL ;
            $data = "data_mcl.txt" ;
            print OUT "data=open(\"$data\",\"a\") \ndata.write(\"$file_MCL\"+\"\\t\"+str($sim_mcl)+\"\\n\") \ndata.close()\n" ;
            $temp_mcl_str = '';
        }


        for ($j ; $j <=$ES_num_files ; $j++) {
            $file_ES = "ES_".$j ;       #get ES cluster, lets say es_j
            open (ES_FILES, "< $result_directory/Separate_ES_files_$number_es/$file_ES") or die $!; 
            $line_es = <ES_FILES>;
            while ($line_es) {
                chomp $line_es ;
                $line_es = "GO_".$line_es ;
                print OUT2 "$line_es=[$hash{$line_es}]\n" ;
                if (defined ($hash{$line_es})) {
                    $temp_es_str = $line_es.",".$temp_es_str; }
            $line_es = <ES_FILES>;
            }
            chop $temp_es_str ;
            $sim_es = "sim_".$file_ES ;
            if (!($temp_es_str eq '')) {
                if ($temp_es_str =~ m /,/) {
                    print OUT2 "$sim_es= tree.GS2([$temp_es_str])\n" ; }
                else {
                    print OUT2 "$sim_es=\"One_FOUND\"\n" ; } }
                
            else {
                print OUT2 "$sim_es=\"NOT_FOUND\"\n" ; }
            $data = "data_es.txt" ;
            print OUT2 "data=open(\"$data\",\"a\") \ndata.write(\"$file_ES\"+\"\\t\"+str($sim_es)+\"\\n\") \ndata.close()\n" ;

            $temp_es_str= '' ;
        }

        close(OUT)  ;
        close(OUT2) ;
        close(ES_FILES) ;
        close(MCL_FILES) ;

        }
        #system 'GS2_ES_data.py'
        copy("$dir_files/Orig_pyGS2.py",$result_directory) or die "Failed to copy Orig_pyGS2.py: $!\n";
        copy("$dir_files/go_daily-termdb.obo-xml",$result_directory) or die "Failed to copy go_daily-termdb.obo-xml: $!\n";
        
        
        chdir("$result_directory") ;
        $new_pwd = getcwd() ;
        system("python", "GS2_ES_data.py") == 0 or die "Python script returned error $?";
        print ".......Done with python file for ES\n" ;
        my @path_files = <$path2/*>;
        foreach $filee (@path_files) {
            chdir("$filee") or die "$! for changing directory";
            system("python", "GS2_MCL_data.py") == 0 or die "Python script returned error $?";
        }
        print ".......Done with python file for MCL files\n" ;
        my @path_files = <$path2/*>;
        foreach $filee (@path_files) {
            chdir("$filee") or die "$! for changing directory";
            system "rm -rf go_daily-termdb.obo-xml" ;
            unlink("go_daily-termdb.obo-xml") ;
            system "rm -rf Orig_pyGS2.py" ;
            unlink("Orig_pyGS2.py") ;
            system "rm -rf Orig_pyGS2.pyc" ;
            unlink("Orig_pyGS2.pyc") ;
        }

    print "All GS2 files are generated.\t".(localtime),"\n"; ;
}

################################################################################################
sub Find_Neighbor {
    #print "$pwd\n" ;
    chdir($pwd);
    chdir ($result_directory) ;
    system("python", "$result_directory/1_print_out_neighbors.py", "$dir_files/Halophiles_data") == 0 or die "Python script returned error $?";
    rename "list_of_neighbors", "list_of_neighbors_of_$number_mcl";
    print "Neighbors in Data file are detected.\t".(localtime),"\n";
}

################################################################################################
sub Find_Known_groups {
    open (OUT, "> $result_directory/Half_Known_GO_clusters.txt") ;
    open (DATA_ES, "< $result_directory/GS2_ES_data.py") or die $! ;
    $line = <DATA_ES> ; #skip the first three lines
    $line = <DATA_ES> ;
    $line = <DATA_ES> ;

    while($line){
        chomp $line;
        $temp_line_counter = 0 ;
        $known_go_count =0 ;
        $temp_string = "" ;
        $flag = 0 ;
        if ($line == "") {
            $line = <DATA_ES>;
            chomp $line;
        }
        
        while (!($line =~ m/sim/)){ 
            $flag =1 ;
            $temp_string = $temp_string."\n". $line ;
            $temp_line_counter++ ;
            if (!($line =~ m/=\[\]/ ) ) {
                $known_go_count++;
            }
            $line = <DATA_ES> ;
            chomp $line;
        }  

        if (($known_go_count > 1) && ($flag)) {
            print OUT "$temp_string\n";
            print OUT "$line\n" ;
            $line = <DATA_ES> ; #data = open
            print OUT "$line" ;
            $line = <DATA_ES> ; #data.write
            print OUT "$line" ;
            $line = <DATA_ES> ; #data.close
            print OUT "$line" ;     
        }
        else {
            $line = <DATA_ES> ;
            $line = <DATA_ES> ;
            $line = <DATA_ES> ;
        }

        $line = <DATA_ES> ;
    }

    close(DATA_ES) ;
    close(OUT); 

    print ".......Finding known groups for ES is done.\n" ;

    $path = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        open (MCL_OUT, ">$path/$filee/Half_Known_GO_clusters.txt") ;
        open (MCL_files, "<$path/$filee/GS2_MCL_data.py") or die $! ;

        $line2 = <MCL_files> ; #skip the first three lines
        $line2 = <MCL_files> ;
        $line2 = <MCL_files> ;

        while($line2){

            chomp $line2;
            $temp_line_counter = 0 ;
            $known_go_count =0 ;
            $temp_string = "" ;

            $flag = 0 ;
            if ($line2 == "") {
                $line2 = <MCL_files>;
                chomp $line2;
            }
            while (!($line2 =~ m/sim/)){    
                $flag=1 ;
                $temp_string = $temp_string."\n". $line2 ;
                $temp_line_counter++ ;
                if (!($line2 =~ m/=\[\]/)){
                    $known_go_count++;
                }
                $line2 = <MCL_files> ;
                chomp $line2;
            }  

            if (($known_go_count > 1) && ($flag)) {
                print MCL_OUT "$temp_string\n";
                print MCL_OUT "$line2\n" ;
                $line2 = <MCL_files> ; #data = open
                print MCL_OUT "$line2" ;
                $line2 = <MCL_files> ; #data.write
                print MCL_OUT "$line2" ;
                $line2 = <MCL_files> ; #data.close
                print MCL_OUT "$line2" ;        
            }
            else {
                $line2 = <MCL_files> ;
                $line2 = <MCL_files> ;
                $line2 = <MCL_files> ;
            }

            $line2 = <MCL_files> ;
        }
        close(MCL_OUT) ;
        close(MCL_files);
    }
    print "Known groups for ES and MCL are found.\t".(localtime),"\n"; ;
}
################################################################################################

sub Prediction_Using_All {
    open (predict_file, ">$result_directory/predictions_for_es.txt") or die $!;
    open (GO_FILE, "<$dir_files/Halophiles_id_GOs.txt") or die $!;
    open (ES_SET_GO, ">$result_directory/All_Extreme_set_GO_based_on_set.txt") or die $! ;

    $line_go = <GO_FILE> ;
    %HASH_GO_FILE =() ;
    while ($line_go){
        chomp $line_go ;
        ($go_id,@GoAnnot) = split ("\t", $line_go) ;
        $temp_string = join("," , @GoAnnot) ;
        $HASH_GO_FILE{$go_id} = $temp_string ;
        $line_go = <GO_FILE> ;  
    }
    print ".......Reading Halophiles_id_GOs.txt is now over.\n" ;
    close(GO_FILE) ;

    open (ES_clusters, "<$result_directory/Half_Known_GO_clusters.txt") or die $! ;
    $line = <ES_clusters> ; #first_line_is_empty
    $line = <ES_clusters> ;
    chomp $line;
    %existing_gos_in_es = ();
    %unknown_gos_in_es = ();
    $flag=0 ;

    %set_prediction= ();

    $i=0; 
    while ($line) {
        @array_of_gos_in_set= () ;
        $line_counter=0 ;
        chomp $line;
        while ((!($line =~ m/sim/)) && ($line ne "") ) { #line is not empty
            $flag =1 ;
            $line_counter++; #shows how many known we had in a set.
            ($name,$go_array) = split("=",$line); #go_array contains [] and comma  name contains GO_ as well.
            if($go_array =~ m/\[\]/){
                if ($name ne "") {
                    $unknown_gos_in_es{$name} = "Undefined" ; 
                    $line_counter--;
                }
            }
            else {
                $go_array =~ s/\]//g ;
                $go_array =~ s/\[//g ;
                @temp = split (",",$go_array) ;
                %temp_hash_now = map { $_ => 1 } @temp;
                undef @temp ;
                @temp= keys %temp_hash_now ;
                undef %temp_hash_now;
                $go_array = join(",",@temp) ;
                $existing_gos_in_es{$name} = $go_array ; #divided by comma
                foreach $key_temp (@temp) {
                    if (!( grep( /^$key_temp/, @array_of_gos_in_set ) )) {
                        push (@array_of_gos_in_set,"$key_temp") ;
                    }   
                }
                
            }
            $line = <ES_clusters> ;
            chomp $line ;
        }
        if ($flag) { 
            $i++;       
            %hash_of_array_of_gos_in_set = map { $_ => 1 } @array_of_gos_in_set ; #set of All go annotations used in the set
            undef @array_of_gos_in_set;
            @array_of_gos_in_set = keys %hash_of_array_of_gos_in_set ;
            $All_gos_in_set = join( ",", @array_of_gos_in_set) ;
            $ladan = $All_gos_in_set ; 
            foreach $key_element (keys %unknown_gos_in_es){ #I changed it from existing_gos_in_es
                    if ($unknown_gos_in_es{$key_element}=="Undefined"){
                        $set_prediction{$key_element} = $All_gos_in_set ;   #set_prediction has All the Gos in a set
                        print predict_file "$key_element\t$set_prediction{$key_element}\n" ;
                    }
            }
            undef @array_of_gos_in_set ;
            undef %hash_of_array_of_gos_in_set ;
            
        }
        else {
            undef %set_prediction ;
        }
        if ($line =~ m /tree/) {
            ($x,$y) = split("=", $line) ;
            $x =~ s /sim_//g ;
        }
        #Now line contains sim
        if ($flag==1) {
            $line = <ES_clusters> ; #open
            $line = <ES_clusters> ; #write
            $line = <ES_clusters> ; #close  
            @ladan_arr=split(",", $ladan);
            %hash_ladan= map {$_ => 1} @ladan_arr ;
            $ladan = join (",", (keys %hash_ladan)) ;
            print ES_SET_GO "$x\t$ladan\n" ;
            undef $hash_ladan
        }
        $flag=0 ;
        $line = <ES_clusters> ; #should be an empty line;

        undef %unknown_gos_in_es ;
        undef %existing_gos_in_es ;
        undef %fix_frequency ;

    }

    predict_file->flush();
    close(ES_clusters);
    close (predict_file) ;

    print ".......Predictions are out. wait for the final prediction file\n" ;

    open (fix_predict_file, "<$result_directory/predictions_for_es.txt") or die $!;
    $line_fix = <fix_predict_file> ;
    %hash_fix = ();
    while ($line_fix){
        chomp $line_fix;
        ($name,$predictions) = split ("\t", $line_fix) ;
        if (!($predictions =~ m/Undefined/)) {
            $hash_fix{$name} = $predictions ;
        }
        $line_fix = <fix_predict_file> ;
    }
    
    unlink("$result_directory/predictions_for_es.txt") ;
    if(-e $fix_predict_file) { print "File $fix_predict_file still exists!"; }
    #else { print "File $fix_predict_file gone.\n";}

    open (final_output, ">$result_directory/All_Final_predictions_for_es.txt") or die $!;
    foreach $kilid (keys %hash_fix){
        print final_output "$kilid\t$hash_fix{$kilid}\n" ; 
        
    }

    undef %hash_fix ;

    $path_now = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path_now/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        $dirr2 = $result_directory."/MCL_".$number_mcl ;
        #unless(-d $dirr2){ mkdir $dirr2 or die $! ; }
        $dirr2 = $dirr2 ."/".$filee ;
        #unless(-d $dirr2){ mkdir $dirr2 or die $! ; }

        %hash_of_array_of_gos_in_set = ();
        @array_of_gos_in_set =();
        open (predict_file, ">$dirr2/predictions_for_MCL_$filee.txt") or die $!;
        open (MCL_SET_GO, ">$dirr2/All_MCL_GO_based_on_set.txt") or die $! ;
        open (MCL_clusters, "<$path_now/$filee/Half_Known_GO_clusters.txt") or die $! ;
        $line = <MCL_clusters> ; #first_line_is_empty
        $line = <MCL_clusters> ;
        chomp $line;
        %existing_gos_in_mcl = ();
        %unknown_gos_in_mcl = ();
        $flag=0 ;

        %set_prediction= ();

        $i=0; 
        while ($line) {
            @array_of_gos_in_set= () ;
            $line_counter=0 ;
            chomp $line;
            while ((!($line =~ m/sim/)) && ($line ne "") ) { #line is not empty                
                $flag =1 ;
                $line_counter++; #shows how many known we had in a set.
                ($name,$go_array) = split("=",$line); #go_array contains [] and comma  name contains GO_ as well.
                    if($go_array =~ m/\[\]/){
                        if ($name ne "") {
                            $unknown_gos_in_mcl{$name} = "Undefined" ; 
                            $line_counter--;
                        }
                    }
                    else {
                        $go_array =~ s/\]//g ;
                        $go_array =~ s/\[//g ;
                        @temp = split (",",$go_array) ;
                        %temp_hash_now = map { $_ => 1 } @temp;
                        undef @temp ;
                        @temp= keys %temp_hash_now ;
                        undef %temp_hash_now;
                        $go_array = join(",",@temp) ;
                        $existing_gos_in_mcl{$name} = $go_array ; #divided by comma
                        foreach $key_temp (@temp) {
                            if (!( grep( /^$key_temp/, @array_of_gos_in_set ) )) {
                                push (@array_of_gos_in_set,"$key_temp") ;
                            }
                        }
                    }
                $line = <MCL_clusters> ;
                chomp $line ;
            }
            if ($flag) { 
                $i++;       
                %hash_of_array_of_gos_in_set = map { $_ => 1 } @array_of_gos_in_set ; #set of All go annotations used in the set
                undef @array_of_gos_in_set;
                @array_of_gos_in_set = keys %hash_of_array_of_gos_in_set ;
                $All_gos_in_set = join( ",", @array_of_gos_in_set) ;
                $ladan = $All_gos_in_set ;
                foreach $key_element (keys %unknown_gos_in_mcl){ #I changed it from existing_gos_in_es
                        if ($unknown_gos_in_mcl{$key_element}=="Undefined"){
                            $set_prediction{$key_element} = $All_gos_in_set ;   #set_prediction has All the Gos in a set
                            print predict_file "$key_element\t$set_prediction{$key_element}\n" ;
                        }
                }
                
                undef @array_of_gos_in_set ;
                undef %hash_of_array_of_gos_in_set ;
                undef %temp_hash;
                undef %temp_hash3 ;             

            }
            else {
                undef %set_prediction ;
            }
            if ($line =~ m /tree/) {
                ($x,$y) = split("=", $line) ;
                $x =~ s /sim_//g ;
            }
            #Now line contains sim
            if ($flag==1) {
                $line = <MCL_clusters> ; #open
                $line = <MCL_clusters> ; #write
                $line = <MCL_clusters> ; #close 
                @ladan_arr=split(",", $ladan);
                %hash_ladan= map {$_ => 1} @ladan_arr ;
                $ladan = join (",", (keys %hash_ladan)) ;
                print MCL_SET_GO "$x\t$ladan\n" ;   
                undef %hash_ladan ;
            }
            $flag=0 ;
            $line = <MCL_clusters> ; #should be an empty line;

            undef %unknown_gos_in_mcl ;
            undef %existing_gos_in_mcl ;
            undef %fix_frequency ;
        }

        predict_file->flush();
        close(MCL_clusters);
        close (predict_file) ;

        print ".......Predictions for $filee are out. wait for the final prediction file\n" ;

        open (fix_predict_file, "<$dirr2/predictions_for_MCL_$filee.txt") or die $!;
        $line_fix = <fix_predict_file> ;
        %hash_fix = ();
        while ($line_fix){
            chomp $line_fix;
            ($name,$predictions) = split ("\t", $line_fix) ;
            if (!($predictions =~ m/Undefined/)) {
                $hash_fix{$name} = $predictions ;
            }
            $line_fix = <fix_predict_file> ;
        }
        system "rm -rf $fix_predict_file" ;
        unlink ("$dirr2/predictions_for_MCL_$filee.txt") ;
        if(-e $fix_predict_file) { print "File $fix_predict_file still exists!"; }
        #else { print "File $fix_predict_file gone.\n";}

        open (final_output, ">$dirr2/All_Final_predictions_for_MCL_$filee.txt") or die $!;
        foreach $kilid (keys %hash_fix){
            print final_output "$kilid\t$hash_fix{$kilid}\n" ; 
        
        }


        undef %hash_fix ;
    }

    print "Prediction using ALL neighbors is now finished.\t".(localtime),"\n"; ;
}
################################################################################################

sub Prediction_Using_Only_Neighbors{

    open (predict_file, ">$result_directory/predictions_for_es.txt") or die $!;


    open (GO_FILE, "<$dir_files/Halophiles_id_GOs.txt") or die $!;
    open (ES_SET_GO, ">$result_directory/Extreme_set_GO_based_on_set.txt") or die $! ;

    $line_go = <GO_FILE> ;
    %HASH_GO_FILE =() ;
    while ($line_go){
        chomp $line_go ;
        ($go_id,@GoAnnot) = split ("\t", $line_go) ;
        $temp_string = join("," , @GoAnnot) ;
        $HASH_GO_FILE{$go_id} = $temp_string ;
        $line_go = <GO_FILE> ;  
    }

    close(GO_FILE) ;
    $neigh_file_name = "list_of_neighbors_of_".$number_mcl ;
    open (Neighbors, "<$result_directory/$neigh_file_name") or die $! ;
    %neighbors_hash =();
    $line_n = <Neighbors> ;
    while($line_n) {
        chomp $line_n ;
        ($node,$neigh_arr) = split ("\t",$line_n);
        $neigh_arr =~ s/\[/GO_/g ;
        $neigh_arr =~ s/\]//g ;
        $neigh_arr =~ s/ //g ;
        $neigh_arr =~ s/,/' GO_'/g ;
        $neigh_arr =~ s/'//g ;
        $node= "GO_".$node ;
        $neighbors_hash{$node} = $neigh_arr ; 
        $line_n = <Neighbors> ;
    }
    print ".......Reading the neighbors File is finished.\n" ;
    close(Neighbors) ;

    open (ES_clusters, "<$result_directory/Half_Known_GO_clusters.txt") or die $! ;
    $line = <ES_clusters> ; #first_line_is_empty
    $line = <ES_clusters> ;
    chomp $line;
    %existing_gos_in_es = ();
    %unknown_gos_in_es = ();
    $flag=0 ;

    %set_prediction= ();

    $i=0; 
    while ($line) {
        @array_of_gos_in_set= () ;
        $line_counter=0 ;
        chomp $line;
        while ((!($line =~ m/sim/)) && ($line ne "") ) { #line is not empty
            #chomp $line;
            
            $flag =1 ;
            $line_counter++; #shows how many known we had in a set.
            ($name,$go_array) = split("=",$line); #go_array contains [] and comma  name contains GO_ as well.
                if($go_array =~ m/\[\]/){
                    if ($name ne "") {
                        $unknown_gos_in_es{$name} = "Undefined" ; 
                        $line_counter--;
                    }
                }
                else {
                    $go_array =~ s/\]//g ;
                    $go_array =~ s/\[//g ;
                    @temp = split (",",$go_array) ;
                    %temp_hash_now = map { $_ => 1 } @temp;
                    undef @temp ;
                    @temp= keys %temp_hash_now ;
                    undef %temp_hash_now;
                    $go_array = join(",",@temp) ;
                    $existing_gos_in_es{$name} = $go_array ; #divided by comma
                    foreach $key_temp (@temp) {
                        if (!( grep( /^$key_temp/, @array_of_gos_in_set ) )) {
                            push (@array_of_gos_in_set,"$key_temp") ;
                        }   
                    }
                }
            $line = <ES_clusters> ;
            chomp $line ;
        }
        if ($flag) { 
            $i++;       
            %hash_of_array_of_gos_in_set = map { $_ => 1 } @array_of_gos_in_set ; #set of all go annotations used in the set
            undef @array_of_gos_in_set;
            @array_of_gos_in_set = keys %hash_of_array_of_gos_in_set ;
            $all_gos_in_set = join( ",", @array_of_gos_in_set) ;
            $ladan = $all_gos_in_set ; 
            undef @array_of_gos_in_set ;
            undef %hash_of_array_of_gos_in_set ;


            %number_of_supporting_neighbors =() ;


            foreach $unknown (keys %unknown_gos_in_es) {
                %go_neighbors= (); #This will keep all the GOs assigned to all neighbors which are in the set
                $neighbors_unknown = $neighbors_hash{$unknown} ; #they are separated by space
                @neighbors_for_unknown_array = split (" ", $neighbors_unknown) ;

                foreach $neighbor_node (@neighbors_for_unknown_array){
                    if (defined $existing_gos_in_es{$neighbor_node}) {

                        #if gos related to the $neighbor_node is a subset of gos in set_prediction
                        @temp_arr =split (",",$HASH_GO_FILE{$neighbor_node}) ; #This is the GOs assigned to the neighbor #This has duplicates
                        %temp_hash2 = map { $_ => 1 } @temp_arr ;
                        foreach $element (%temp_hash2){
                            if ((!(defined $go_neighbors{$unknown})) && ($element ne "")) {
                                $go_neighbors{$unknown}= $element ;
                            }
                            else{
                                if ($element ne ""){
                                    @k = split(",",$go_neighbors{$unknown}) ;
                                    if (!($go_neighbors{$unknown} =~m /$element/)){
                                        $go_neighbors{$unknown} = $go_neighbors{$unknown}.",".$element ;
                                    }
                                }
                            }
                        }
                        undef %temp_hash2;
                        if ($unknown_gos_in_es{$unknown}=="Undefined") {
                            $unknown_gos_in_es{$unknown} = $existing_gos_in_es{$neighbor_node} ;
                        } 
                        else {
                            $unknown_gos_in_es{$unknown} = $unknown_gos_in_es{$unknown}."_".$existing_gos_in_es{$neighbor_node} ;
                        }
                    }
                    #else does nothing because that neighbor was not in the extreme set
                }
            }
                
            undef %temp_hash;
            undef %temp_hash3 ;             


            foreach $now_known (keys %unknown_gos_in_es){
                if ($unknown_gos_in_es{$now_known} =~ m/_/){ #it was more than once
                    @predicted_gos = split ("_",$unknown_gos_in_es{$now_known}) ;
                    
                %hash_string_set = map { $_ => 1 } @predicted_gos; 
                @predicted_gos = keys %hash_string_set ;
                $go_term_predicted = join(",",@predicted_gos) ;

                $unknown_gos_in_es{$now_known} = $go_term_predicted ;
                }
                print predict_file "$now_known\t$unknown_gos_in_es{$now_known}\n" ; 
            }
        }
        else {
            undef %set_prediction ;
        }
        if ($line =~ m /tree/) {
            ($x,$y) = split("=", $line) ;
            $x =~ s /sim_//g ;
        }
        #Now line contains sim
        if ($flag==1) {
            $line = <ES_clusters> ; #open
            $line = <ES_clusters> ; #write
            $line = <ES_clusters> ; #close  
            @ladan_arr=split(",", $ladan);
            %hash_ladan= map {$_ => 1} @ladan_arr ;
            $ladan = join (",", (keys %hash_ladan)) ;
            print ES_SET_GO "$x\t$ladan\n" ;
            undef $hash_ladan
        }
        $flag=0 ;
        $line = <ES_clusters> ; #should be an empty line;

        undef %unknown_gos_in_es ;
        undef %existing_gos_in_es ;
        undef %fix_frequency ;
        

        #undef %set_prediction ;
    }

    predict_file->flush();
    close(ES_clusters);
    close (predict_file) ;

    print ".......Predictions are out. wait for the final prediction file\n" ;

    open (fix_predict_file, "<$result_directory/predictions_for_es.txt") or die $!;
    $line_fix = <fix_predict_file> ;
    %hash_fix = ();
    while ($line_fix){
        chomp $line_fix;
        ($name,$predictions) = split ("\t", $line_fix) ;
        if (!($predictions =~ m/Undefined/)) {
            $hash_fix{$name} = $predictions ;
        }
        $line_fix = <fix_predict_file> ;
    }
    #system "rm -rf $fix_predict_file" ;
    unlink("predictions_for_es.txt") ;
    if(-e $fix_predict_file) { print "File $fix_predict_file still exists!"; }
    #else { print "File $fix_predict_file gone.";}

    open (final_output, ">$result_directory/Final_predictions_for_es.txt") or die $!;
    foreach $kilid (keys %hash_fix){
        @temp = split(",",$hash_fix{$kilid}) ; 
        %hash_final= map {$_ => 1} @temp ;
        @temp = keys %hash_final ;
        $hash_fix{$kilid} = join (",",@temp) ;
        print final_output "$kilid\t$hash_fix{$kilid}\n";

    }

    undef %hash_fix ;
    
    $path_now = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path_now/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        #$dirr2 = $result_directory."/predicted_".$number_mcl ;
        $dirr2 = $result_directory."/MCL_".$number_mcl ;
        unless(-d $dirr2){ mkdir $dirr2 or die $! ; }
        $dirr2= $dirr2."/".$filee ;
        unless(-d $dirr2){ mkdir $dirr2 or die $! ; }

        %hash_of_array_of_gos_in_set = ();
        @array_of_gos_in_set =();
        open (predict_file, ">$dirr2/predictions_for_MCL_$filee.txt") or die $!;
        open (MCL_SET_GO, ">$dirr2/MCL_GO_based_on_set.txt") or die $! ;
        open (MCL_clusters, "<$path_now/$filee/Half_Known_GO_clusters.txt") or die $! ;
        $line = <MCL_clusters> ; #first_line_is_empty
        $line = <MCL_clusters> ;
        chomp $line;
        %existing_gos_in_mcl = ();
        %unknown_gos_in_mcl = ();
        $flag=0 ;

        %set_prediction= ();


        $i=0; 
        while ($line) {
            @array_of_gos_in_set= () ;
            $line_counter=0 ;
            chomp $line;
            while ((!($line =~ m/sim/)) && ($line ne "") ) { #line is not empty
                #chomp $line;
                
                $flag =1 ;
                $line_counter++; #shows how many known we had in a set.
                ($name,$go_array) = split("=",$line); #go_array contains [] and comma  name contains GO_ as well.
                    if($go_array =~ m/\[\]/){
                        if ($name ne "") {
                            $unknown_gos_in_mcl{$name} = "Undefined" ; 
                            $line_counter--;
                        }
                    }
                    else {
                        $go_array =~ s/\]//g ;
                        $go_array =~ s/\[//g ;
                        @temp = split (",",$go_array) ;
                        %temp_hash_now = map { $_ => 1 } @temp;
                        undef @temp ;
                        @temp= keys %temp_hash_now ;
                        undef %temp_hash_now;
                        $go_array = join(",",@temp) ;
                        $existing_gos_in_mcl{$name} = $go_array ; #divided by comma
                        foreach $key_temp (@temp) {
                            if (!( grep( /^$key_temp/, @array_of_gos_in_set ) )) {
                                push (@array_of_gos_in_set,"$key_temp") ;
                            }   
                        }
                    }
                $line = <MCL_clusters> ;
                chomp $line ;
            }
            if ($flag) { 
                $i++;       
                %hash_of_array_of_gos_in_set = map { $_ => 1 } @array_of_gos_in_set ; #set of all go annotations used in the set
                undef @array_of_gos_in_set;
                @array_of_gos_in_set = keys %hash_of_array_of_gos_in_set ;
                $all_gos_in_set = join( ",", @array_of_gos_in_set) ;
                $ladan = $all_gos_in_set ;
                foreach $key_element (keys %unknown_gos_in_mcl){ #I changed it from existing_gos_in_es
                        if ($unknown_gos_in_mcl{$key_element}=="Undefined"){
                            $set_prediction{$key_element} = $all_gos_in_set ;   #set_prediction has all the Gos in a set
                        }
                }
                undef @array_of_gos_in_set ;
                undef %hash_of_array_of_gos_in_set ;


                %number_of_supporting_neighbors =() ;


                foreach $unknown (keys %unknown_gos_in_mcl) {
                    %go_neighbors= (); #This will keep all the GOs assigned to all neighbors which are in the set
                    $neighbors_unknown = $neighbors_hash{$unknown} ; #they are separated by space
                    @neighbors_for_unknown_array = split (" ", $neighbors_unknown) ;

                    foreach $neighbor_node (@neighbors_for_unknown_array){
                        if (defined $existing_gos_in_mcl{$neighbor_node}) {

                            #if gos related to the $neighbor_node is a subset of gos in set_prediction
                            @temp_arr =split (",",$HASH_GO_FILE{$neighbor_node}) ; #This is the GOs assigned to the neighbor #This has duplicates
                            %temp_hash2 = map { $_ => 1 } @temp_arr ;
                            foreach $element (%temp_hash2){
                                if ((!(defined $go_neighbors{$unknown})) && ($element ne "")) {
                                    $go_neighbors{$unknown}= $element ;
                                }
                                else{
                                    if ($element ne ""){
                                        @k = split(",",$go_neighbors{$unknown}) ;
                                        if (!($go_neighbors{$unknown} =~m /$element/)){
                                            $go_neighbors{$unknown} = $go_neighbors{$unknown}.",".$element ;
                                        }
                                    }
                                }
                            }
                            undef %temp_hash2;
                            if ($unknown_gos_in_mcl{$unknown}=="Undefined") {
                                $unknown_gos_in_mcl{$unknown} = $existing_gos_in_mcl{$neighbor_node} ;
                            } 
                            else {
                                $unknown_gos_in_mcl{$unknown} = $unknown_gos_in_mcl{$unknown}."_".$existing_gos_in_mcl{$neighbor_node} ;
                            }
                        }
                        #else does nothing because that neighbor was not in the extreme set
                    }
                }
                undef %temp_hash;
                undef %temp_hash3 ;             

                %fix_frequency = ();


                foreach $now_known (keys %unknown_gos_in_mcl){
                    if ($unknown_gos_in_mcl{$now_known} =~ m/_/){ #it was more than once
                        @predicted_gos = split ("_",$unknown_gos_in_mcl{$now_known}) ;
                    
                    %hash_string_set = map { $_ => 1 } @predicted_gos; 
                    @predicted_gos = keys %hash_string_set ;
                    $go_term_predicted = join(",",@predicted_gos) ;

                    $unknown_gos_in_mcl{$now_known} = $go_term_predicted; #---------->10/29
                    }

                    print predict_file "$now_known\t$unknown_gos_in_mcl{$now_known}\n" ;    
                }
            }
            else {
                undef %set_prediction ;
            }
            if ($line =~ m /tree/) {
                ($x,$y) = split("=", $line) ;
                $x =~ s /sim_//g ;
            }
            #Now line contains sim
            if ($flag==1) {
                $line = <MCL_clusters> ; #open
                $line = <MCL_clusters> ; #write
                $line = <MCL_clusters> ; #close 
                @ladan_arr=split(",", $ladan);
                %hash_ladan= map {$_ => 1} @ladan_arr ;
                $ladan = join (",", (keys %hash_ladan)) ;
                print MCL_SET_GO "$x\t$ladan\n" ;   
                undef %hash_ladan ;
            }
            $flag=0 ;
            $line = <MCL_clusters> ; #should be an empty line;

            undef %unknown_gos_in_mcl ;
            undef %existing_gos_in_mcl ;
            undef %fix_frequency ;
            

            #undef %set_prediction ;
        }

        predict_file->flush();
        close(MCL_clusters);
        close (predict_file) ;

        open (fix_predict_file, "<$dirr2/predictions_for_MCL_$filee.txt") or die $!;
        $line_fix = <fix_predict_file> ;
        %hash_fix = ();
        while ($line_fix){
            chomp $line_fix;
            ($name,$predictions) = split ("\t", $line_fix) ;
            if (!($predictions =~ m/Undefined/)) {
                $hash_fix{$name} = $predictions ;
            }
            $line_fix = <fix_predict_file> ;
        }
        system "rm -rf $fix_predict_file" ;
        unlink ("$dirr2/predictions_for_MCL_$filee.txt") ;
        if(-e $fix_predict_file) { print "File $fix_predict_file still exists!"; }
        #else { print "File $fix_predict_file gone.";}

        open (final_output, ">$dirr2/Final_predictions_for_MCL_$filee.txt") or die $!;
        foreach $kilid (keys %hash_fix){
            @temp = split(",",$hash_fix{$kilid}) ; 
            %hash_final= map {$_ => 1} @temp ;
            @temp = keys %hash_final ;
            $hash_fix{$kilid} = join (",",@temp) ;
            print final_output "$kilid\t$hash_fix{$kilid}\n";

        }

        undef %hash_fix ;
        print ".......Predictions for $filee are out. wait for the final prediction file\n" ;
    }
    undef @temp;
    print "Predictions using ONLY neighbors is now finished.\t".(localtime),"\n";
}

################################################################################################

sub Compare_predictions{
    
    if (@_[0] eq "Y") {
        $flag = 1;
    }
    else {
        $flag=0 ;
    }

    if ($flag){
    print ".......File is going to be $result_directory/All_Final_predictions_for_es.txt\n" ;   
    open (ES, "<$result_directory/All_Final_predictions_for_es.txt") or die $! ;
    }
    else{
    print ".......File is going to be $result_directory/Final_predictions_for_es.txt\n" ;    
    open (ES, "<$result_directory/Final_predictions_for_es.txt") or die $! ;
    }


    $line = <ES> ;
    while($line){
        chomp $line;
        ($name,$GOs) = split ("\t",$line) ;
        $name =~ s/GO_//g ;
        $hash_go{$name} = $GOs ;
        $FINAL_HASH{$name} = "ES:" . $GOs; 
        $line=<ES>;
    }
    close(ES) ;

    $path_predicted = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path_predicted/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        #print "filee is $filee\n";
        $dirr2 = $path_predicted."/".$filee ;
        if ($flag){
            open (MCL, "<$dirr2/All_Final_predictions_for_MCL_$filee.txt") or die $! ;  
        }
        else {
            open (MCL, "<$dirr2/Final_predictions_for_MCL_$filee.txt") or die $! ;      
        }
        
        $line2 = <MCL> ;
        while($line2){
            chomp $line2;
            ($name,$GOs) = split ("\t",$line2) ;
            $name =~ s/GO_//g ;
            if (defined $hash_go{$name}) {
                @separate_go = split (",",$GOs) ;
                %hash_separate_go = map { $_ => 1 } @separate_go;
                $previously_known = $hash_go{$name} ;
                @previously_known_arr = split (",",$previously_known) ;
                foreach $element (@previously_known_arr){
                    if (defined $hash_separate_go{$element}) {
                        delete $hash_separate_go{$element} ;
                    }
                }
                @remaining_keys = keys %hash_separate_go ;
                $term_remaining_keys = join (",",@remaining_keys) ;
                #$MCL_hash{$name} = $term_remaining_keys ;
                if ($term_remaining_keys ne "") {
                    $FINAL_HASH {$name} = $FINAL_HASH {$name} ."\tMCL_$filee:". $term_remaining_keys ; 
                }
            }
            else {
                #$MCL_hash{$name} = $GOs;
                if (defined $FINAL_HASH{$name}) {
                    $FINAL_HASH {$name} = $FINAL_HASH {$name} ."\tMCL_$filee:". $GOs ;
                }
                else {
                    $FINAL_HASH {$name} = "MCL_$filee:". $GOs ;
                }
            }
            $line2=<MCL>;
        }
        close (MCL) ;
    }
    if ($flag) {
        open (output, ">$result_directory/All_Comparison_between_ES_MCL_predictions.txt") or die $!;
        open (only_es, ">$result_directory/All_only_predicted_by_es.txt") or die $!;
        open (only_mcl, ">$result_directory/All_only_predicted_by_mcl.txt") or die $!;    
    }
    else {
        open (output, ">$result_directory/Comparison_between_ES_MCL_predictions.txt") or die $!;
        open (only_es, ">$result_directory/only_predicted_by_es.txt") or die $!;
        open (only_mcl, ">$result_directory/only_predicted_by_mcl.txt") or die $!;    
    }

    $filee_list = join("\tMCL_",@path_files) ;
    foreach $key (keys %FINAL_HASH) {
        if ($FINAL_HASH{$key} =~ m /ES/){
            if ($FINAL_HASH{$key} =~ m /MCL/){
                print output "$key\t$FINAL_HASH{$key}\n" ;
            }
            else {
                print only_es "$key\t$FINAL_HASH{$key}\n";
            }
            delete $FINAL_HASH{$key} ;
        }
    }

    foreach $key (keys %FINAL_HASH) {
        print only_mcl "$key\t$FINAL_HASH{$key}\n" ;

    }

    close(output) ;
    close(only_es) ;
    close(only_mcl) ;
    undef $flag ;

    print " Comparing predictions are now finished for case =@_[0].\t".(localtime),"\n"; ;
}
################################################################################################

sub Clusters_of_difference{
    if (@_[0] eq "Y") {
        $flag = 1;
    }
    else {
        $flag=0 ;
    }

    open(ES_file, "<$result_directory/tabbed_numbered_$ES_file.txt") or die $! ;
    %hash_es = ();
    $line = <ES_file> ;
    while($line) {
        chomp $line ;
        ($es_name,@members) = split ("\t", $line) ;
        foreach $member (@members) {
            if (defined $hash_es{$member}) {
                $hash_es{$member} = $hash_es{$member} . "," . $es_name ;
            }
            else {
                $hash_es{$member} = $es_name ;
            }
        }
        $line = <ES_file> ;
    }

    close(ES_file) ;

    $path_mcl = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path_mcl/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee=$alaki[-1] ;
        $dirr2 = $path_mcl."/".$filee ;
        $str= "$dirr2/numbered_MCL_".$filee."_".$number_mcl.".txt" ;
        #print $str ;
        open(MCL_file, "<$str") or die $! ;
        %hash_MCL = ();
        $line = <MCL_file> ;
        while($line) {
            chomp $line ;
            ($MCL_name,@members) = split ("\t", $line) ;
            foreach $member (@members) {
                if (defined $hash_MCL{$member}) {
                    $hash_MCL{$member} = $hash_MCL{$member} . "\t" . $MCL_name ;
                }
                else {
                    $hash_MCL{$member} = $filee.":".$MCL_name ;
                }
            }
            $line = <MCL_file> ;
        }

        close(MCL_file) ;

    }

    open (Output, ">$result_directory/clustered_comparison_between_ES_MCL_predictions.txt") or die $! ;
    if ($flag){
        open (input, "<$result_directory/All_Comparison_between_ES_MCL_predictions.txt") or die $! ;
    }
    else{
        open (input, "<$result_directory/Comparison_between_ES_MCL_predictions.txt") or die $! ;
    }
    $line = <input> ;
    while ($line) {
        chomp $line ;
        ($name, $rest)=split ("\t", $line) ;
        print Output "$line\n$hash_es{$name}\t$hash_MCL{$name}\n\n" ;
        $line = <input> ;
    }
    undef $flag ;
    print "Finding different clusters is now finished for case =@_[0].\t".(localtime),"\n"; ;
}

################################################################################################

sub How_Correct{

    if (@_[0] eq "Y") {
        $flag = 1;
    }
    else {
        $flag=0 ;
    }

    if ($flag) {
    open (outes, ">$result_directory/All_accuracy_of_only_es.txt") or die $! ;
    open (outmcl, ">$result_directory/All_accuracy_of_only_mcl.txt") or die $! ;
    open (outboth, ">$result_directory/All_accuracy_of_Both_algorithms.txt") or die $! ;
    }
    else {
        open (outes, ">$result_directory/accuracy_of_only_es.txt") or die $! ;
        open (outmcl, ">$result_directory/accuracy_of_only_mcl.txt") or die $! ;
        open (outboth, ">$result_directory/accuracy_of_Both_algorithms.txt") or die $! ;
    }
    open (GO_file, "<$result_directory//Halophiles_id_GOs.txt") or die $! ;

    %hash = ();

    $line=<GO_file> ;
    while($line){
        chomp $line;
        ($name,@GOS) = split("\t", $line) ;
        %temp_hash_now = map { $_ => 1 } @GOS;
        undef @GOS;
        @GOS = keys %temp_hash_now ;
        $go_string = join ("_",@GOS);
        $name =~ s/GO_//g ;
        $hash{$name} = $go_string ;
        $line=<GO_file> ;
    }
    #print ".......Done with the Original GO ID file.\n" ;

    if ($flag) {
        open (only_es, "<$result_directory/All_only_predicted_by_es.txt") or die $! ;
    }
    else{
        open (only_es, "<$result_directory/only_predicted_by_es.txt") or die $! ; 
    }
    $line = <only_es> ;
    print outes "ES predictions:\n" ;
    while ($line){
        chomp $line ;
        ($name, $info)=split ("\t", $line) ;
        $info =~ s/ES://g ;
        $size_array_predict = @array_predict =split (",", $info) ;
        $size_hash = @hash_info = split ("_", $hash{$name}) ;
        $Intersection = 0 ;
        foreach $prediction (@array_predict) {
            foreach $element (@hash_info) {
                if ($prediction eq $element) {
                    $Intersection++ ;
                }
            }
        }
        $SorensenDice_index = (2 * $Intersection) / ($size_hash + $size_array_predict) ;
        $SorensenDice_index = sprintf "%.2f", $SorensenDice_index;
        print outes "$name\t$SorensenDice_index\n" ;
        $line = <only_es> ;
    }

    if ($flag) {
        open (only_mcl, "<$result_directory/All_only_predicted_by_mcl.txt") or die $! ;
    }
    else{
        open (only_mcl, "<$result_directory/only_predicted_by_mcl.txt") or die $! ;
    }



    $line = <only_mcl> ;
    print outmcl "MCL predictions:\n" ;
    while ($line){
        chomp $line ;
        ($name, @info_arr)=split ("\t", $line) ;
        $size_hash = @hash_info = split ("_", $hash{$name}) ;
        print outmcl "$name" ;
        foreach $key (@info_arr){
            ($num_mcl, $info) = split (":", $key)  ;
            $size_array_predict = @array_predict =split (",", $info) ;
            $Intersection = 0 ;
            foreach $prediction (@array_predict) {
                foreach $element (@hash_info) {
                    if ($prediction eq $element) {
                        $Intersection++ ;
                    }
                }
            }
            if (($size_hash + $size_array_predict)==0) {
                $SorensenDice_index = "ERROR"
            }
            else{
                $SorensenDice_index = (2 * $Intersection) / ($size_hash + $size_array_predict) ;
                $SorensenDice_index = sprintf "%.2f", $SorensenDice_index;    
            }
            
            print outmcl "\t$num_mcl:$SorensenDice_index" ;
        }
        print outmcl "\n" ;
        
        $line = <only_mcl> ;
    }

    if ($flag) {
        open (both, "<$result_directory/All_Comparison_between_ES_MCL_predictions.txt") or die $! ;
    }
    else{
        open (both, "<$result_directory/Comparison_between_ES_MCL_predictions.txt") or die $! ;
    }


    $line = <both> ;
    print outboth "ES and MCL predictions:\n" ;
    while ($line){
        chomp $line ;
        ($name, @info_arr)=split ("\t", $line) ;
        $size_hash = @hash_info = split ("_", $hash{$name}) ;
        print outboth "$name" ;
        foreach $key (@info_arr){
            ($num_mcl, $info) = split (":", $key)  ;
            $size_array_predict = @array_predict =split (",", $info) ;
            $Intersection = 0 ;

            foreach $prediction (@array_predict) {
                foreach $element (@hash_info) {
                    if ($prediction eq $element) {
                        $Intersection++ ;
                    }
                }
            }

            if (($size_hash + $size_array_predict)==0) {
                $SorensenDice_index = "ERROR"
            }
            else{
                $SorensenDice_index = (2 * $Intersection) / ($size_hash + $size_array_predict) ;
                $SorensenDice_index = sprintf "%.2f", $SorensenDice_index;    
            }
            
            print outboth "\t$num_mcl:$SorensenDice_index" ;
        }
        print outboth "\n" ;
        
        $line = <both> ;
    }

    print "Finding different clusters is now finished for case =@_[0].\t".(localtime),"\n"; ;
}


################################################################################################

sub Clusters_sizes{
    if (@_[0] eq "Y") {
        $flag = 1;
    }
    else {
        $flag=0 ;
    }

    if ($flag) {
        open (in_accuracy, "<$result_directory/All_accuracy_of_only_es.txt") or die $! ;  
    }
    else {
        open (in_accuracy, "<$result_directory/accuracy_of_only_es.txt") or die $! ;  
    }

    %hash_es_accuracy = ();
    $line = <$in_accuracy>; #ES PREDICTIONS
    $line = <$in_accuracy>;
    while ($line) {
         chomp $line  ;
         ($GO_id, $accuracy) = split ("\t", $line) ;
         $hash_es_accuracy{$GO_id} = "ES:".$accuracy ;
         $line = <$in_accuracy>;
    }

    if ($flag) {
        open (in2_accuracy, "<$result_directory/All_accuracy_of_only_mcl.txt") or die $! ;    
    }
    else {
        open (in2_accuracy, "<$result_directory/accuracy_of_only_mcl.txt") or die $! ;    
    }
    %hash_mcl_accuracy = ();
    $line = <in2_accuracy>; #ES PREDICTIONS
    $line = <in2_accuracy>;
    while ($line) {
         chomp $line  ;
         ($GO_id, @accuracy) = split ("\t", $line) ;
         $accuracy = join("\t",@accuracy) ;
         $hash_mcl_accuracy{$GO_id} = $accuracy ;
         undef @accuracy ;
         $line = <in2_accuracy>;
    }

    if ($flag) {
        open (inboth_accuracy, "<$result_directory/All_accuracy_of_Both_algorithms.txt") or die $! ;  
    }
    else {
        open (inboth_accuracy, "<$result_directory/accuracy_of_Both_algorithms.txt") or die $! ;  
    }
    #%hash_mcl_accuracy = ();
    $line = <inboth_accuracy>; #ES PREDICTIONS
    $line = <inboth_accuracy>;
    while ($line) {
         chomp $line  ;
         ($GO_id, @accuracy) = split ("\t", $line) ;
         $ES = shift @accuracy ;
         #$ES =~ s/ES://g ;
         $accuracy = join("\t",@accuracy) ;
         #print "ES is $ES and accuracy is $accuracy\n" 
         $hash_es_accuracy{$GO_id} = $ES ;
         $hash_mcl_accuracy{$GO_id} = $accuracy ;
         undef @accuracy ;
         $line = <inboth_accuracy>;
    }

    open (in_es, "<$result_directory/tabbed_numbered_$ES_file.txt") or die $! ;
    %hash_es_name = ();
    %hash_es_members = ();
    $line = <in_es> ;
    while ($line) {
        chomp $line ;
        ($name, @members) = split ("\t", $line);
        $size_es = @members;
        $hash_es_name{$name} = $size_es ;
        foreach $key (@members){
            $hash_es_members{$key} = $name;
        }
        undef @members;
        $line = <in_es> ;
    }

    $path = $result_directory."/MCL_".$number_mcl ;
    $path2 = $result_directory."/MCL_".$number_mcl ;
    unless(-d $path2){ mkdir $path2 or die $! ;}
    my @path_files = <$path/*>;
        
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee = pop(@alaki) ;
        $dirr = $path2."/".$filee ;
        unless(-d $dirr){ mkdir $dirr or die $! ; }

        $filename = "numbered_MCL_".$filee."_".$number_mcl.".txt" ;
        open (in_mcl, "<$path/$filee/$filename") or die $!; 

        %hash_mcl_name = ();
        %hash_mcl_members = ();
        $line = <in_mcl> ;
        while ($line) {
            chomp $line ;
            ($name, @members) = split ("\t", $line);
            $size_mcl = @members;
            $hash_mcl_name{$name} = $size_mcl ;
            foreach $key (@members){
                if (!(defined $hash_mcl_members{$key})){
                    $hash_mcl_members{$key} = $name
                }
                else {
                    $hash_mcl_members{$key} = $hash_mcl_members{$key} ."\t" .$name ;
                }
            }
            undef @members;
        $line = <in_mcl> ;
        }
        open (out, ">$dirr/Cluster_size_comparison.txt") or die $! ;
        print out "GOIDs\tCluster Size ES\t Cluster size MCL\tAccuracy ES \t Accuracy MCL:\n" ;
        %union = ();
        %union =(%hash_es_members,%hash_mcl_members);
        foreach $kilid (keys %union){
            @temp = split ("\t", $hash_mcl_accuracy{$kilid});
            $pattern = "MCL_".$filee.":" ;
            foreach $element (@temp){
                if ($element=~ m /$pattern/) {
                    $match = $element ;
                }
            }
            
            if ( (defined $hash_es_members{$kilid}) || (defined $hash_mcl_members{$kilid}) ){
                if (!(defined $hash_es_members{$kilid})){
                    $hash_es_members{$kilid} = "NULL";
                    $hash_es_name{$hash_es_members{$kilid}} = "0.00";
                }
                if (!(defined $hash_es_accuracy{$kilid})){
                    $hash_es_accuracy{$kilid}= "ES:NULL";
                }

                if (!(defined $hash_mcl_members{$kilid})){
                    $hash_mcl_members{$kilid} = "NULL";
                    $hash_mcl_name{$hash_es_members{$kilid}} = "0.00";
                }
                if (!($match)){
                    $match= "MCL_".$filee.":NULL";
                }
                print out "$kilid\t$hash_es_members{$kilid}\t$hash_mcl_members{$kilid}\tSize_es:$hash_es_name{$hash_es_members{$kilid}}\tSize_mcl:$hash_mcl_name{$hash_mcl_members{$kilid}}\t$hash_es_accuracy{$kilid}\t$match\n" ;
            }
            undef $match;
        }

    }
    print "Finding cluster sizes is now finished for case =@_[0].\t".(localtime),"\n"; 

}


################################################################################################

sub Matlab_gs2{

    
    $dir_es = $result_directory.'/Separate_ES_files_'.$number_es ;
    my @path_es = <$dir_es/*>;
    $number_of_es = @path_es ;

    open (out_es_axis, ">$matlab_files/ES_MCL_Matlab_$number_mcl.m") ;
    print out_es_axis "ES_axis =[ " ;

    $i= 1 ;
    while ($i<$number_of_es){
        $string_temp_es = 'ES_'.$i ;
        print out_es_axis "\'$string_temp_es\' " ;
        $i++ ;
    }
    print out_es_axis "];\n\n" ;

    print out_es_axis "ES_data = [ " ;
    $k = "6a_".$number."_gs2" ;
    open(in_es_gs2, "< $result_directory/data_es.txt") or die $!;
    $line = <in_es_gs2> ;
    while ($line) {
        chomp $line ;
        
        ($num,$value) = split("\t",$line) ;
        if ($value =~ m /FOUND/){
                $value = "NaN" ;
        }
        if ($value==0){
            $value = "NaN" ;
        }
        print out_es_axis "$value " ;
        $line = <in_es_gs2> ;
    }
    print out_es_axis "];\n\n" ;

    $path = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path/*>;


    foreach $filee (@path_files) {
    $counter = 0;
        @alaki = split ("/",$filee);
        $filee= pop(@alaki) ;

        $path3 = $path."/".$filee."/Separate_MCL_files_".$number_mcl ;
        $number_of_mcl = @numbers = <$path3/*>;
        print out_es_axis "MCL_$filee =[ " ;
        $i=1;
        while( $i<$number_of_mcl){
            $string_temp_mcl = 'MCL_'.$i ;
            print out_es_axis "\'$string_temp_mcl\' " ;
            $i++ ;
        }
        print out_es_axis "];\n\n" ;
        print out_es_axis "MCL_data_$filee = [ " ;

        open(in_mcl_gs2, "<$path/$filee/data_mcl.txt")  or die $!;
        $line = <in_mcl_gs2> ;
        while ($line) {
            chomp $line ;
            #print "$line" ;
            ($num,$value) = split("\t",$line) ;
            if ($value =~ m /FOUND/){
                $value = "NaN" ;
            }
            if ($value==0){
                $value = "NaN" ;
            }
            print out_es_axis "$value " ;
            $line = <in_mcl_gs2> ;
        }
        print out_es_axis "];\n\n" ;        
    }   

    print "Matlab files for GS2 now finished.\t".(localtime),"\n"; 
}

    $path = $parent.'/4_mcl_numbering/'.$number ;
################################################################################################

sub Get_Sizes_MATLAB{

    $dir_es = $result_directory."/tabbed_numbered_$ES_file".".txt" ;
    print $dir_es ;
    open (in_es, "<$dir_es") or die $! ;
    open (out_es, ">$result_directory/ES_sizes.txt") or die $! ;
    open (out_matlab, ">$matlab_files/Matlab_size_clusters.m" ) or die $! ;
    print out_matlab "ES_size_clusters =[" ;
    $line = <in_es> ;
    while ($line) {
        chomp $line ;
        ($name,@array)=split ("\t",$line);
        $size_es_ha = @array ;
        print out_es "$name\t$size_es_ha\n" ;
        print out_matlab "$size_es_ha," ;
        $line = <in_es> ;
    }
    print out_matlab "] ;\n" ;

    $path = $result_directory."/MCL_".$number_mcl ;

    my @path_files = <$path/*>;
    foreach $filee (@path_files) {
        @alaki = split ("/",$filee);
        $filee= pop(@alaki) ;
        $dirr = $path."/".$filee ;
        unless(-d $dirr){ mkdir $dirr or die $! ; }

        $file_mcls = $path."/".$filee.'/numbered_MCL_'.$filee."_".$number_mcl.".txt" ;
        open (in_mcl, "<$file_mcls") or die $! ;
        open (out_mcl, ">$dirr/MCL_sizes.txt") or die $! ;
        print out_matlab "MCL_";
        print out_matlab $filee ;
        print out_matlab "_size_clusters = [" ;
        $line = <in_mcl> ;
        while ($line) {
            chomp $line ;
            ($name,@array)=split ("\t",$line);
            $size_mcl_ha = @array ;
            print out_mcl "$name\t$size_mcl_ha\n" ;
            print out_matlab "$size_mcl_ha," ;
            $line = <in_mcl> ;
        }
        print out_matlab "] ;\n" ;
    }

    close (in_es);
    close(in_mcl);
    close(out_matlab);
    close(out_mcl);
    close(out_es);

    print "Getting sizes for Matlab files for GS2 now finished.\t".(localtime),"\n"; 
}

################################################################################################

sub Size_Avg_Accuracy{
    open (matlab , ">$matlab_files/Cluster_size_vs_avg_Accuracy.m") or die $! ;
    open (es_size, "<$result_directory/ES_sizes.txt") or die $!;
    %hash_size_es = ();
    %rev_hash_size_es = ();
    $line = <es_size> ;
    ($name,$max_size) = split ("\t", $line) ;
    chomp $max_size ;
    while ($line) {
        chomp $line;
        ($name,$size) = split ("\t", $line) ;
        $rev_hash_size_es{$name} = $size ; #$rev_hash{ES_1} = 989 
        if (!(defined $hash_size_es{$size})) {
            $hash_size_es{$size} = $name ;  
        }
        else {
            $hash_size_es{$size} = $hash_size_es{$size} ."\t".$name  ; #hash{989}= ES_1 ; hash{290} = ES_32\tES_33
        }
        $line = <es_size> ;
    }

    open (accuracy_gs2, "<$result_directory/data_es.txt") or die $! ;

    %hash_size_score = ();
    $line = <accuracy_gs2> ;
    while ($line) {
        chomp $line ;
        ($name,$score) = split ("\t", $line) ;
        if ($score=~ m /FOUND/ ){
            $score = "nan" ;
        }
        $hash_size_score{$name} = $score ;
        $line = <accuracy_gs2> ;
    }
    %clusters_accuracy = ();
    foreach $kilid (keys %hash_size_score){
        $count = 0;
        $accuracy = 0;
        $reverse_size = $rev_hash_size_es{$kilid} ;
        if (!(defined $clusters_accuracy{$reverse_size})){
            @array_size = split("\t", $hash_size_es{$reverse_size}) ;
            $size_array = @array_size ;
            if ($size_array>1) {
                $avg = 0 ;
                foreach $element (@array_size) {
                    
                    if (!($hash_size_score{$element} eq "nan")) {
                            $count++;
                            $accuracy = $accuracy + $hash_size_score{$element} ;
                        }
                }
                $avg = $accuracy / $count ;
                undef @array_size ;

            }
            else {
                $avg = $hash_size_score{$hash_size_es{$reverse_size}} ;
            }
            $clusters_accuracy{$reverse_size} = $avg ;  

        }
        undef @array_size;
    }
        
    $counter = 2 ;
    $temp_line_es_scores = "nan" ;
    $temp= " " ;
    delete $clusters_accuracy{$temp} ;
    foreach $key (sort {$a<=>$b} keys %clusters_accuracy) {

        while($counter<$key) {
            $counter++ ;
            $temp_line_es_scores = $temp_line_es_scores  . ",nan"   ;   
        }
        $temp_line_es_scores = $temp_line_es_scores  . "," .$clusters_accuracy{$key}    ;
        $counter++; 
    }


    $temp_line_es_scores = "ES_score_clusters = [" . $temp_line_es_scores . "] ;" ;
    $temp_line_es_scores =~s/\[,/\[/g ;
    print matlab "$temp_line_es_scores\n\n" ;


    undef %clusters_accuracy;
    undef %hash_size_es ;
    undef %hash_size_score ;
    undef %rev_hash_size_es ;

    $path = $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path/*>;


    foreach $filee (@path_files) {
    $counter = 0;
        @alaki = split ("/",$filee);
        $filee= pop(@alaki) ;
        open (mcl_size, "<$path/$filee/MCL_sizes.txt") or die $!;
        %hash_size_mcl = ();
        %rev_hash_size_mcl = ();
        $line = <mcl_size> ;
        ($name,$mcl_max) = split ("\t", $line) ;
        chomp $mcl_max ;
        while ($line) {
            chomp $line;
            ($name,$size) = split ("\t", $line) ;
            $rev_hash_size_mcl{$name} = $size ; 
            if (!(defined $hash_size_mcl{$size})) {
                $hash_size_mcl{$size} = $name ; 
            }
            else {
                $hash_size_mcl{$size} = $hash_size_mcl{$size} ."\t".$name  ; 
            }
            $line = <mcl_size> ;
        }

        $file_name=$result_directory."/MCL_".$number_mcl ;
        open (accuracy_gs2, "<$file_name/$filee/data_mcl.txt") or die $! ;

        %hash_size_score = ();
        $line = <accuracy_gs2> ;
        
        while ($line) {
            chomp $line ;
            ($name,$score) = split ("\t", $line) ;
            if ($score=~ m /FOUND/ ){
                $score = "nan" ;
            }
            $hash_size_score{$name} = $score ;
            $line = <accuracy_gs2> ;
        }
        %clusters_accuracy = ();
        foreach $kilid (keys %hash_size_score){
            $count = 0;
            $accuracy = 0;
            $reverse_size = $rev_hash_size_mcl{$kilid} ;
            if (!(defined $clusters_accuracy{$reverse_size})){
                @array_size = split("\t", $hash_size_mcl{$reverse_size}) ;
                $size_array = @array_size ;
                if ($size_array>1) {
                    $avg = 0 ;
                    foreach $element (@array_size) {
                        if (!($hash_size_score{$element} eq "nan")) {
                            $count++;
                            $accuracy = $accuracy + $hash_size_score{$element} ;
                        }

                    }

                    $avg = $accuracy / $count ;
                    undef @array_size;
                }
                else {
                    $avg = $hash_size_score{$hash_size_mcl{$reverse_size}} ;
                }
                $clusters_accuracy{$reverse_size} = $avg ;  
            }
            undef @array_size;
        }
            
        $counter = 2 ;
        $temp_line_mcl_scores = "nan" ;

        $temp= "" ;
        delete $clusters_accuracy{$temp} ;
        foreach $key (sort {$a<=>$b} keys %clusters_accuracy) {
            while($counter<$key) {
                $counter++ ;
                $temp_line_mcl_scores = $temp_line_mcl_scores  . ",nan"     ;   
            }
            $temp_line_mcl_scores = $temp_line_mcl_scores  . "," .$clusters_accuracy{$key}  ;
            $counter++; 
        }
        $i  = $max_size - $mcl_max ;
        while($i){
            $temp_line_mcl_scores = $temp_line_mcl_scores .",nan" ;
            $i = $i-1;      
        }

        $temp_line_mcl_scores = "MCL_".$filee."_score_clusters = [" . $temp_line_mcl_scores . "] ;" ;
        $temp_line_mcl_scores =~s/\[,/\[/g ;
        print matlab "$temp_line_mcl_scores\n\n" ;


        undef %clusters_accuracy;
        undef %hash_size_mcl ;
        undef %hash_size_score ;
        undef %rev_hash_size_mcl ;
    }

    print "Done with Size vs Avg accuracy Matlab files for GS2.\t".(localtime),"\n"; 
}

################################################################################################

sub Cleaning_files{
    chdir("$result_directory") or die "$! for changind directory";

    system "rm -rf 1_print_out_neighbors.py" ;    
    system "rm -rf Halophiles_id_GOs.txt" ;
    system "rm -rf GS2_ES_data.py" ;
    system "rm -rf Orig_pyGS2.py" ;
    system "rm -rf Orig_pyGS2.pyc" ;


    $neigh_file_name = "list_of_neighbors_of_".$number_mcl ;
    unlink($neigh_file_name) ;
    if(-e $neigh_file_name) { print "File $neigh_file_name still exists!"; }
    else { print ".......Neighbor file is now deleted.\n" ;}

    unlink("go_daily-termdb.obo-xml") ;
    system "rm -rf go_daily-termdb.obo-xml" ;

    $file = $result_directory."/Separate_ES_files_".$number_es;
    #print ".......$file is going to be deleted\n";
    system "rm -rf $file" ;
    unlink("$file") ;
    

    $path= $result_directory."/MCL_".$number_mcl ;
    my @path_files = <$path/*>;
    foreach $files_there (@path_files){
        chdir("$files_there") ;
        $file = $files_there."/Separate_MCL_files_".$number_mcl;
        #print ".......$file is going to be deleted\n";
        system "rm -rf $file" ;
        unlink($file) ;
        system "rm -rf GS2_MCL_data.py" ;
        
    
        chdir("../");
    }

    # chdir("$pwd") ;
    # my @folders = File::Find::Rule->in( <$result_directory/*>);
    # foreach my $file (@folders){
    #     if ($file =~m /Separate/){
    #         system "rm -rf $file" ;
    #         unlink($file) ;
    #         if(-e $file) { print "File $file still exists!"; }
    #     }
    # }

    print ".......All separate files are now deleted.\n" ;

    print "Cleaning Files is now finished.\t".(localtime),"\n"; 
}
