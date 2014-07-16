using QLIM

context PATIENT // TODO: Look at turning this into a parameter with a 'with' statement

parameter MeasurePeriod default interval[Date(2013, 1, 1), Date(2014, 1, 1))

valueset "Other Female Reproductive Conditions" = ValueSet("2.16.840.1.113883.3.464.1003.111.12.1006")
valueset "Genital Herpes" = ValueSet("2.16.840.1.113883.3.464.1003.110.12.1049")
valueset "Genococcal Infections and Venereal Diseases" = ValueSet("2.16.840.1.113883.3.464.1003.112.12.1001")
valueset "Inflammatory Diseases of Female Reproductive Organs" = ValueSet("2.16.840.1.113883.3.464.1003.112.12.1004")
valueset "Chlamydia" = ValueSet("2.16.840.1.113883.3.464.1003.112.12.1003")
valueset "HIV" = ValueSet("2.16.840.1.113883.3.464.1003.120.12.1003")
valueset "Syphilis" = ValueSet("2.16.840.1.113883.3.464.1003.112.12.1002")
valueset "Complications of Pregnancy, Childbirth and the Puerperium" = ValueSet("2.16.840.1.113883.3.464.1003.111.12.1012")
valueset "Pregnancy Test" = ValueSet("2.16.840.1.113883.3.464.1003.111.12.1011")
valueset "Pap Test" = ValueSet("2.16.840.1.113883.3.464.1003.108.12.1017")
valueset "Lab Tests During Pregnancy" = ValueSet("2.16.840.1.113883.3.464.1003.111.12.1007")
valueset "Lab Tests for Sexually Transmitted Infections" = ValueSet("2.16.840.1.113883.3.464.1003.110.12.1051")
valueset "Chlamydia Screening" = ValueSet("2.16.840.1.113883.3.464.1003.110.12.1052")
valueset "Diagnostic Studies During Pregnancy" = ValueSet("2.16.840.1.113883.3.464.1003.111.12.1008")

let InDemographic = 
	AgeAt(start of MeasurePeriod) >= 16
		and AgeAt(start of MeasurePeriod) < 24
		and Gender = "female"

let SexuallyActive =
	exists ([Diagnosis: "Other Female Reproductive Conditions"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Genital Herpes"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Genococcal Infections and Venereal Diseases"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Inflammatory Diseases of Female Reproductive Organs"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Chlamydia"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "HIV"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Syphilis"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([Diagnosis: "Complications of Pregnancy, Childbirth and the Puerperium"] C where C.effectiveTime overlaps before MeasurePeriod)
		or exists ([DiagnosticStudy, Order: "Diagnostic Studies During Pregnancy"] R where R.effectiveTime during MeasurePeriod)
		or exists ([LaboratoryTest, Order: "Pap Test"] R where R.effectiveTime during MeasurePeriod)
		or exists ([LaboratoryTest, Order: "Lab Tests During Pregnancy"] R where R.effectiveTime during MeasurePeriod)
		or exists ([LaboratoryTest, Order: "Lab Tests for Sexually Transmitted Infections"] R where R.observedAtTime during MeasurePeriod)

let IPP =
	SexuallyActive and InDemographic

let DENOM =
	IPP

let NUMER =
	DENOM
		and exists ([LaboratoryTest: "Chlamydia Screening"] R where R.effectiveTime during MeasurePeriod)


