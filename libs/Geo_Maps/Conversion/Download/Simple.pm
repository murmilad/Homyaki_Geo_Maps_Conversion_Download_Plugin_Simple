package Homyaki::Geo_Maps::Conversion::Download::Simple;

use strict;

use File::Copy;
use Homyaki::Geo_Maps::Conversion::Download::Constants;

use Data::Dumper;

use base 'Homyaki::Geo_Maps::Conversion';

sub convert {
	my $self = shift;
	my %h = @_;

	my $maps = $h{maps};

	my $geo_data  = $self->{params}->{geo_data};
	my $maps_path = $self->{params}->{maps_path};

	my $error;

	my $dest = &MAPS_DESTANTION;

	Homyaki::Logger::print_log("Geo_Maps Download::Simple - maps: " . Dumper($maps));

	foreach my $map (@{$maps}){

		my $map_name = $map->{name};
		my $map_path = $map->{path};

		copy($map_path, "$dest/$maps_path/$map_name")
			or $error = $!;

		if (!$error){
			chmod(oct('0666'),"$dest/$maps_path/$map_name");
		} else {
			Homyaki::Logger::print_log("Geo_Maps Download::Simple - Error: $!");
		}

		if (!$error){
			foreach my $image_type (@{&IMAGE_TYPES}) {
				my $gif_name = $map_name;
				$gif_name =~ s/\.map$/.$image_type/;

				my $gif_path = $map_path;
				$gif_path =~ s/\.map$/.$image_type/;

				if (-f $gif_path) {

					if (!$error){
						copy($gif_path, "$dest/$maps_path/$gif_name")
							or $error = $!;
					} else {
						Homyaki::Logger::print_log("Geo_Maps Download::Simple - Error: $!");
					}


					if (!$error){
						chmod(oct('0666'), "$dest/$maps_path/$gif_name");
					} else {
						last;
						Homyaki::Logger::print_log("Geo_Maps Download::Simple - Error: $!");
					}
				}
			}
		} else {
			Homyaki::Logger::print_log("Geo_Maps Download::Simple - Error: $!");
		}
	}
}

1;
__END__
			foreach my $map (@intersect_maps){
				Homyaki::Logger::print_log("Geo_Maps - geo_type_id = $map->{geo_type_id}; geo_type_list = " . Dumper($geo_type_map));

				if ($map->{bounds_ext}){
					my ($map_contour) = thaw($map->{bounds_ext});
					my $i = 1;
					foreach my $bound (@{$map_contour}){
						$params->{"map_${index}_vertex_${i}_lat"} = $bound->[0];
						$params->{"map_${index}_vertex_${i}_lng"} = $bound->[1];
						$i++;
					}
				} else {
					$params->{"map_${index}_vertex_1_lat"} = $map->{bounds_1_lat};
					$params->{"map_${index}_vertex_1_lng"} = $map->{bounds_1_lng};
					$params->{"map_${index}_vertex_2_lat"} = $map->{bounds_2_lat};
					$params->{"map_${index}_vertex_2_lng"} = $map->{bounds_2_lng};
					$params->{"map_${index}_vertex_3_lat"} = $map->{bounds_3_lat};
					$params->{"map_${index}_vertex_3_lng"} = $map->{bounds_3_lng};
					$params->{"map_${index}_vertex_4_lat"} = $map->{bounds_4_lat};
					$params->{"map_${index}_vertex_4_lng"} = $map->{bounds_4_lng};
				}
				$params->{"map_${index}_color"}        = $geo_type_map->{$map->{geo_type_id}};
			
				my $map_name = $map->{name};
				my $map_path = $map->{path};

				copy($map_path, "$dest/$maps_path/$map_name")
					or $error = $!;

				if (!$error){
					`chmod 0666 $dest/$maps_path/$map_name`;
				} else {
					Homyaki::Logger::print_log("Geo_Maps - Error: $!");
				}

				if (!$error){
					foreach my $image_type (@{&IMAGE_TYPES}) {
						my $gif_name = $map_name;
						$gif_name =~ s/\.map$/.$image_type/;
						my $gif_path = $map_path;
						$gif_path =~ s/\.map$/.$image_type/;

						if (-f $gif_path) {

							if (!$error){
								copy($gif_path, "$dest/$maps_path/$gif_name")
									or $error = $!;
							} else {
								Homyaki::Logger::print_log("Geo_Maps - Error: $!");
							}


							if (!$error){
								`chmod 0666 $dest/$maps_path/$gif_name`;
							} else {
								last;
								Homyaki::Logger::print_log("Geo_Maps - Error: $!");
							}
						}
					}
				} else {
					Homyaki::Logger::print_log("Geo_Maps - Error: $!");
				}
			

				$index++;
			}
			my $zip_result = `cd $dest; zip -rm0 $maps_path.zip $maps_path 2>&1;`;
			Homyaki::Logger::print_log("Geo_Maps - Zip: $zip_result");

			if ($zip_result =~ /skipped:\s+(\d+)/i && $1 > 0) {
				$error = "$1 files skipped";
			} elsif (!(-f "$dest/$maps_path.zip")){
				$error = "No enough space";
			}

			if (!$error){
				$params->{zip_dest} = "/topo/$maps_path.zip";
			} else {
				$result->{errors}->{base}->{errors} = ["Can't create zip archive ($error). Try to select less region."];
				`cd $dest; rm -rf $maps_path; rm -f $maps_path.zip;`;
			}

			my @task_types = Homyaki::Task_Manager::DB::Task_Type->search(
				handler => 'Homyaki::Task_Manager::Task::Delete_Downloaded_Files'
			);

			if (scalar(@task_types) > 0) {

				my $task = Homyaki::Task_Manager->create_task(
					task_type_id => $task_types[0]->id(),
					params => {
						file_path => "$dest/$maps_path.zip",
					}
				);
			}

		} else {
			$result->{errors}->{base}->{errors} = ['Too many maps selected (' . scalar(@intersect_maps) . ' maps). Please select less region. Maximim ' . &MAPS_LIMIT . ' maps.'];
		}
		Homyaki::Logger::print_log('Geo_Maps - params ' . Dumper($params) . ' maps');

	}

        Homyaki::Interface::Gallery::Blog->set_params(
                params      => $params,
                permissions => $permissions,
        );

	return $result;
}
