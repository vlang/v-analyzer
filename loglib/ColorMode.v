module loglib

pub enum ColorMode {
	auto
	always
	never
}

fn get_color_mode_by_name(name string) ?ColorMode {
	return match name {
		'auto' { ColorMode.auto }
		'always' { ColorMode.always }
		'never' { ColorMode.never }
		else { none }
	}
}
