class SetupState {
  final bool hasProfile;
  final bool hasFarm;
  final bool hasCrop;
  final bool hasSubscription;
  final bool hasKyc;

  const SetupState({
    this.hasProfile = false,
    this.hasFarm = false,
    this.hasCrop = false,
    this.hasSubscription = false,
    this.hasKyc = false,
  });

  SetupState copyWith({
    bool? hasProfile,
    bool? hasFarm,
    bool? hasCrop,
    bool? hasSubscription,
    bool? hasKyc,
  }) {
    return SetupState(
      hasProfile: hasProfile ?? this.hasProfile,
      hasFarm: hasFarm ?? this.hasFarm,
      hasCrop: hasCrop ?? this.hasCrop,
      hasSubscription: hasSubscription ?? this.hasSubscription,
      hasKyc: hasKyc ?? this.hasKyc,
    );
  }
}
