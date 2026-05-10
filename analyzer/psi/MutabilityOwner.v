module psi

pub interface MutabilityOwner {
	is_mutable() bool
	mutability_modifiers() ?&MutabilityModifiers
}
