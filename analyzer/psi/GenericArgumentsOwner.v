module psi

pub interface GenericArgumentsOwner {
	type_arguments() ?&GenericTypeArguments
}
