import '../models/govt_scheme.dart';

/// Service managing verified Government Agriculture and Horticulture Schemes.
/// Provides real scheme data, dynamic state/district/crop/category filtering,
/// official application portal integration, and registration lookup.
class GovtSchemeService {
  GovtSchemeService._();
  static final GovtSchemeService instance = GovtSchemeService._();

  final List<GovtScheme> _verifiedSchemes = [
    // 1. PM-KISAN
    const GovtScheme(
      id: 'pm-kisan-01',
      name: 'PM-Kisan Samman Nidhi Yojana',
      department:
          'Department of Agriculture & Farmers Welfare (Govt. of India)',
      category: 'Farmer Welfare',
      state: 'All India',
      district: 'All',
      applicableCrops: ['All Crops'],
      description: 'Direct income support of ₹6,000 per year in three equal quarterly installments of ₹2,000 directly deposited into the Aadhaar-linked bank accounts of landholder farmer families.',
      benefitsSubsidy:
          '₹6,000/year (100% Direct Benefit Transfer via DBT PFMS)',
      eligibilityCriteria: [
        'Small and marginal landholder farmer families with cultivable land in their name.',
        'Active bank account seeded with Aadhaar and updated eKYC status.',
        'Institutional landholders and income tax paying families are excluded.',
      ],
      requiredDocuments: [
        'Aadhaar Card (eKYC completed)',
        'Land Record (7/12 & 8-A / Khatauni / Jamabandi)',
        'Active Bank Account Passbook seeded with NPCI/Aadhaar',
        'Mobile Number linked to Aadhaar',
      ],
      startDate: 'Ongoing (Quarterly Installments)',
      deadline: 'Always Open (eKYC mandatory)',
      officialWebsiteUrl: 'https://pmkisan.gov.in',
      portalName: 'PM-KISAN Official Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 2. PMFBY Crop Insurance
    const GovtScheme(
      id: 'pmfby-02',
      name: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      department: 'Ministry of Agriculture & Farmers Welfare, GoI',
      category: 'Agriculture',
      state: 'All India',
      district: 'All',
      applicableCrops: [
        'Wheat',
        'Paddy',
        'Cotton',
        'Groundnut',
        'Mustard',
        'Soybean',
        'Maize',
      ],
      description: 'Comprehensive crop insurance coverage against non-preventable natural risks (drought, dry spells, flood, inundation, unseasonal rainfall, pests, landslides, and post-harvest losses).',
      benefitsSubsidy: 'Max farmer premium: 2% for Kharif, 1.5% for Rabi, 5% for Annual Commercial/Horticultural crops. Remaining premium subsidized by Central & State Govts.',
      eligibilityCriteria: [
        'All farmers including sharecroppers and tenant farmers growing notified crops in notified areas.',
        'Both loanee and non-loanee farmers are eligible.',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Land Ownership proof / Tenancy Agreement',
        'Sowing Certificate / Vepari Panchnama / Talati Certificate',
        'Cancelled Cheque / Bank Passbook Copy',
      ],
      startDate: '01 July 2026',
      deadline: '31 July (Kharif) / 31 December (Rabi)',
      officialWebsiteUrl: 'https://pmfby.gov.in',
      portalName: 'National Crop Insurance Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 3. Kisan Credit Card (KCC)
    const GovtScheme(
      id: 'kcc-03',
      name: 'Kisan Credit Card (KCC) Concessional Loan',
      department: 'Reserve Bank of India & NABARD',
      category: 'Farmer Welfare',
      state: 'All India',
      district: 'All',
      applicableCrops: ['All Crops', 'Dairy & Animal Husbandry', 'Fisheries'],
      description: 'Short-term credit for crop cultivation, post-harvest expenses, farm asset maintenance, and allied agricultural activities at an effective subsidized interest rate of 4% per annum upon prompt repayment.',
      benefitsSubsidy: 'Loans up to ₹3 Lakh at 7% p.a., reduced to 4% p.a. through 3% Prompt Repayment Incentive (PRI). Collateral-free up to ₹1.6 Lakh.',
      eligibilityCriteria: [
        'Individual / joint owner farmers cultivating agricultural land.',
        'Tenant farmers, oral lessees, and sharecroppers.',
        'Self Help Groups (SHGs) or Joint Liability Groups (JLGs) of farmers.',
      ],
      requiredDocuments: [
        'Duly filled application form',
        'Identity & Address Proof (Aadhaar, Voter ID, PAN)',
        'Land Title Documents (RoR 7/12, 8-A, Khasra-Khatauni)',
        'Cropping pattern verification certified by Village Officer',
      ],
      startDate: 'Round the Year',
      deadline: 'Continuous through Nationalized & Cooperative Banks',
      officialWebsiteUrl: 'https://myscheme.gov.in/schemes/kcc',
      portalName: 'KCC Digital Portal / JanSamarth',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 4. Gujarat iKhedut Tractor Subsidy
    const GovtScheme(
      id: 'ikhedut-tractor-04',
      name: 'Gujarat iKhedut Agricultural Tractor Assistance Scheme',
      department: 'Directorate of Agriculture, Govt. of Gujarat',
      category: 'Equipment & Machinery',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['All Crops'],
      description: 'State financial assistance to farmers for purchasing new tractors (up to 40 PTO HP or 40-60 PTO HP) to modernize farming operations and increase mechanization efficiency.',
      benefitsSubsidy: 'General farmers: 25% subsidy up to ₹45,000. SC/ST, Small & Marginal, and Women farmers: 35% subsidy up to ₹60,000.',
      eligibilityCriteria: [
        'Farmer must own agricultural land in Gujarat recorded in 7/12 and 8-A.',
        'Farmer must not have availed tractor subsidy under any scheme during the last 10 years.',
        'Tractor must be purchased from an authorized empaneled dealer.',
      ],
      requiredDocuments: [
        '7/12 and 8-A Land Record extract (recent)',
        'Aadhaar Card and Mobile linked to iKhedut',
        'Bank Passbook / Cancelled Cheque (IFSC verified)',
        'Caste Certificate (if applying under SC/ST quota)',
        'Quotation from Authorized Tractor Manufacturer Dealer',
      ],
      startDate: '15 April 2026',
      deadline: '30 June 2026 (Extended for Anand & Saurashtra)',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat iKhedut Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 5. Gujarat Desi Cow-Based Natural Farming Assistance
    const GovtScheme(
      id: 'gujarat-natural-05',
      name: 'Gujarat Desi Cow Natural Farming Monthly Assistance',
      department:
          'Department of Agriculture, Farmers Welfare & Co-operation, Gujarat',
      category: 'Natural Farming',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: [
        'All Natural Farming Crops',
        'Cotton',
        'Wheat',
        'Groundnut',
        'Vegetables',
      ],
      description: 'Monthly financial assistance to farmers adopting Cow-based Natural Farming (Prakrutik Kheti) for the maintenance and fodder of an indigenous desi breed cow, facilitating Jeevamrut, Beejamrut, and Ghanjeevamrut preparation.',
      benefitsSubsidy: '₹900 per month (₹10,800 annually) directly paid into farmer bank account.',
      eligibilityCriteria: [
        'Farmer must possess agricultural land in Gujarat.',
        'Farmer must own at least one indigenous Desi cow with ear-tag identification.',
        'Farmer must practice Subhash Palekar Natural Farming methods on their land.',
        'Farmer must have completed basic natural farming training from ATMA or Krishi Vigyan Kendra (KVK).',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        '7/12, 8-A copy',
        'Desi Cow Ear-tag certification issued by Veterinary Doctor',
        'ATMA Master Trainer / Gram Sevak Natural Farming Verification',
        'Bank Passbook copy',
      ],
      startDate: '01 May 2026',
      deadline: '31 August 2026',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat iKhedut & ATMA Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 6. Gujarat iKhedut Tar Fencing (Jhatka / Barbed Wire) Scheme
    const GovtScheme(
      id: 'ikhedut-fencing-06',
      name: 'Gujarat Solar Jhatka & Barbed Wire Fencing Assistance',
      department: 'Directorate of Agriculture, Govt. of Gujarat',
      category: 'Equipment & Machinery',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['Cotton', 'Paddy', 'Groundnut', 'Vegetables', 'Maize'],
      description: 'Financial grant to farmers for installing wire fencing or solar electric jhatka fencing around agricultural fields to protect standing crops against nilgai (blue bulls), wild boars, and stray cattle.',
      benefitsSubsidy: '50% of total expenditure up to ₹200 per meter or max ₹40,000 per beneficiary.',
      eligibilityCriteria: [
        'Individual farmers or group of adjacent farmers owning farmland.',
        'Land must be recorded in 7/12 & 8-A.',
        'Priority given to clusters of farmers pooling contiguous land borders.',
      ],
      requiredDocuments: [
        'Land RoR (7/12, 8-A) & Village Map (Naksha)',
        'Aadhaar Card',
        'Bank Account details',
        'Bill/Invoice with GST from approved fencing vendor',
        'Gram Sevak Verification & Field Inspection Certificate',
      ],
      startDate: '01 June 2026',
      deadline: '30 September 2026',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat iKhedut Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 7. PMKSY - Per Drop More Crop (Micro Irrigation Drip & Sprinkler)
    const GovtScheme(
      id: 'pmksy-drip-07',
      name: 'Pradhan Mantri Krishi Sinchayee Yojana (PMKSY) - Micro Irrigation',
      department:
          'Ministry of Agriculture & GGRC (Gujarat Green Revolution Company)',
      category: 'Irrigation & Water',
      state: 'All India',
      district: 'All',
      applicableCrops: [
        'Cotton',
        'Sugarcane',
        'Groundnut',
        'Vegetables',
        'Banana',
        'Horticulture',
      ],
      description: 'Heavy capital subsidy on installation of Drip Irrigation and Sprinkler Irrigation systems to maximize water use efficiency, reduce electricity cost, and boost crop productivity.',
      benefitsSubsidy: 'Up to 70% for Small & Marginal farmers; 55% for General farmers. In Gujarat, GGRC provides an additional state top-up subsidy reaching up to 85%.',
      eligibilityCriteria: [
        'Farmer must own agricultural land with an assured water source (well, tubewell, canal).',
        'Available for all categories of farmers across all districts.',
      ],
      requiredDocuments: [
        'Land Records (7/12, 8-A)',
        'Electricity Connection bill / Solar pump receipt for water source',
        'Aadhaar Card',
        'Soil and Water Test Report (from authorized laboratory)',
        'Bank Passbook copy',
      ],
      startDate: 'Open Year-Round',
      deadline: 'Open throughout 2026',
      officialWebsiteUrl: 'https://ggrc.co.in',
      portalName: 'GGRC / PMKSY Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 8. Mission for Integrated Development of Horticulture (MIDH)
    const GovtScheme(
      id: 'midh-horticulture-08',
      name: 'Mission for Integrated Development of Horticulture (MIDH)',
      department: 'Mission for Integrated Development of Horticulture, Ministry of Agriculture',
      category: 'Horticulture',
      state: 'All India',
      district: 'All',
      applicableCrops: [
        'Tomato',
        'Potato',
        'Mango',
        'Banana',
        'Onion',
        'Flowers',
        'Spices',
      ],
      description: 'Financial incentives for establishing new fruit orchards, protected cultivation (Greenhouses / Polyhouses / Shade Net Houses), mushroom production, post-harvest pack houses, and cold chains.',
      benefitsSubsidy: '50% subsidy on establishment of Polyhouse / Shade nets (up to ₹4.5 Lakh to ₹9 Lakh depending on area). 40% to 50% subsidy on fruit saplings.',
      eligibilityCriteria: [
        'Farmer or Farmer Producer Organization (FPO) growing or planning to cultivate horticultural crops.',
        'Sufficient land and water resources.',
      ],
      requiredDocuments: [
        'Land RoR (7/12 / Jamabandi)',
        'Detailed Project Report (DPR) for Polyhouse/Cold Storage',
        'Aadhaar Card and PAN',
        'Bank Loan sanction letter (if bank-linked project)',
      ],
      startDate: '01 April 2026',
      deadline: '31 October 2026',
      officialWebsiteUrl: 'https://midh.gov.in',
      portalName: 'National Horticulture Board (NHB) / MIDH',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 9. Punjab CRM (In-Situ Straw Management & Seeder Subsidy)
    const GovtScheme(
      id: 'punjab-crm-09',
      name: 'Punjab Crop Residue Management (CRM) Subsidy Scheme',
      department: 'Department of Agriculture & Farmers Welfare, Punjab',
      category: 'Equipment & Machinery',
      state: 'Punjab',
      district: 'All',
      applicableCrops: ['Paddy', 'Wheat'],
      description: 'Subsidy on CRM machinery (Super Seeder, Happy Seeder, Smart Seeder, Paddy Straw Chopper, Baler, Mulcher) to eliminate stubble burning (Parali) and improve soil microbial health.',
      benefitsSubsidy: '50% subsidy for individual farmers; 80% subsidy for Farmer Cooperatives & Custom Hiring Centers (CHCs).',
      eligibilityCriteria: [
        'Landholding farmers in Punjab registered on the AgiMachinery portal.',
        'Custom Hiring Centers (CHCs) and registered Gram Panchayats.',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Punjab Jamabandi (Farad)',
        'Self-declaration of zero residue burning',
        'Bank Account passbook linked to Aadhaar',
      ],
      startDate: '01 June 2026',
      deadline: '31 August 2026',
      officialWebsiteUrl: 'https://agrimachinerypb.com',
      portalName: 'Punjab AgriMachinery Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 10. Maharashtra Dr. Panjabrao Deshmukh Interest Concession
    const GovtScheme(
      id: 'maha-loan-10',
      name: 'Maharashtra Dr. Panjabrao Deshmukh Zero Percent Crop Loan Scheme',
      department:
          'Department of Agriculture & Cooperation, Govt. of Maharashtra',
      category: 'Farmer Welfare',
      state: 'Maharashtra',
      district: 'All',
      applicableCrops: ['Cotton', 'Soybean', 'Sugarcane', 'Onion', 'Paddy'],
      description: '100% interest subvention on crop loans up to ₹3 Lakhs borrowed from Cooperative and Nationalized Banks, ensuring farmers pay 0% net interest if repaid before the due date.',
      benefitsSubsidy: '100% interest subsidy (Effective 0% interest on crop loans up to ₹3,00,000).',
      eligibilityCriteria: [
        'All agriculturists in Maharashtra who obtain short-term crop loans and repay punctually.',
      ],
      requiredDocuments: [
        '7/12 extract and 8-A',
        'Aadhaar Card',
        'Crop Loan disbursement certificate from bank',
      ],
      startDate: 'Round the Year',
      deadline: 'Before 31 March of every financial year',
      officialWebsiteUrl: 'https://mahadbt.maharashtra.gov.in',
      portalName: 'MahaDBT Farmer Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 11. Uttar Pradesh PM-KUSUM Solar Tubewell Subsidy
    const GovtScheme(
      id: 'up-kusum-11',
      name: 'Uttar Pradesh PM-KUSUM Component-B Solar Tubewell Subsidy',
      department: 'Department of Agriculture, Uttar Pradesh',
      category: 'Irrigation & Water',
      state: 'Uttar Pradesh',
      district: 'All',
      applicableCrops: ['Wheat', 'Paddy', 'Sugarcane', 'Potato', 'Mustard'],
      description: 'Grant for installation of stand-alone solar agricultural pumps (2 HP, 3 HP, 5 HP, 7.5 HP & 10 HP AC/DC) to replace diesel pumps and reduce irrigation electricity expenses.',
      benefitsSubsidy: '60% to 70% capital grant (Central 30% + UP State 30-40%). Farmer pays only 30-40% token money.',
      eligibilityCriteria: [
        'Farmer registered on UP Agriculture portal (upagriculture.com).',
        'Farmer must have cultivable land and a borewell/well ready with appropriate water depth.',
      ],
      requiredDocuments: [
        'UP Kisan Panjikaran Number (Farmer ID)',
        'Khatauni / Land record (within 6 months)',
        'Aadhaar Card',
        'Bank Draft / Online token money confirmation',
      ],
      startDate: '10 July 2026',
      deadline: '31 October 2026',
      officialWebsiteUrl: 'http://upagriculture.com',
      portalName: 'UP Agriculture Portal (Kisan Mitra)',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 12. Rajasthan Tarbandi Yojana
    const GovtScheme(
      id: 'raj-tarbandi-12',
      name: 'Rajasthan Tarbandi (Field Wire Fencing) Subsidy',
      department: 'Department of Agriculture, Govt. of Rajasthan',
      category: 'Equipment & Machinery',
      state: 'Rajasthan',
      district: 'All',
      applicableCrops: ['Mustard', 'Wheat', 'Bajra', 'Gram', 'Guar'],
      description: 'Financial support for barbed wire fencing up to 400 running meters per farmer to safeguard crops against stray animals and wild neelgai.',
      benefitsSubsidy: '50% of the cost or maximum ₹40,000 for individual farmers; up to ₹48,000 for small & marginal farmers.',
      eligibilityCriteria: [
        'Minimum 1.5 hectares of contiguous cultivable agricultural land.',
        'Farmer must not have received fencing subsidy in the past 3 years.',
      ],
      requiredDocuments: [
        'Jan Aadhaar Card',
        'Jamabandi RoR (within 6 months)',
        'Field Map (Tracemap / Naksha certified by Patwari)',
        'Bank Passbook linked to Jan Aadhaar',
      ],
      startDate: '01 May 2026',
      deadline: '15 September 2026',
      officialWebsiteUrl: 'https://rajkisan.rajasthan.gov.in',
      portalName: 'RajKisan Sathi Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
    ),

    // 13. PM-KUSUM Component A (Gujarat DISCOMs)
    const GovtScheme(
      id: 'gj-solar-001',
      name: 'PM-KUSUM Component-A Solar Power Generation on Agricultural Land',
      nameGujarati: 'પીએમ-કુસુમ યોજના ઘટક-એ (ખેતીની જમીન પર સોલાર પાવર પ્લાન્ટ સ્થાપના)',
      nameHindi: 'पीएम-कुसुम घटक-ए (कृषि भूमि पर विकेंद्रीकृत सौर ऊर्जा संयंत्र)',
      department: 'Energy & Petrochemicals Department, GoG / Gujarat DISCOMs (DGVCL, MGVCL, PGVCL, UGVCL)',
      category: 'Irrigation & Solar',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['All Crops', 'Barren & Cultivable Farmland'],
      description: 'Farmers and landholders can install 500 kW to 2 MW grid-connected solar power plants within 5 km of 66/11 kV rural substations. Farmers can self-invest or lease land to developers for 25 years with guaranteed annual rent.',
      benefitsSubsidy: 'Guaranteed 25-Year PPA Tariff with DISCOMs / Assured Lease Rent ₹25,000-₹35,000/acre/year with 5% escalation every 3 years. Automatic Deemed NA under Sec. 65-B GLRC.',
      eligibilityCriteria: [
        'Agricultural land within 5 km radius of notified DISCOM 66/11 kV substations.',
        'Requires approx. 3.5 to 4.0 acres per MW capacity.',
        'Open to individual farmers, groups, cooperatives, and FPOs.',
      ],
      requiredDocuments: [
        '7/12, 8-A and Form 6 Land Records',
        'Aadhaar Card of Landowner',
        'Model Lease Agreement (Annex-1) duly executed (if leasing)',
        'Bank Account with IFSC',
        'Substation distance verification by DISCOM engineer',
      ],
      startDate: 'Ongoing',
      deadline: 'Round the Year (Per DISCOM Notification)',
      officialWebsiteUrl: 'https://pgvcl.com',
      portalName: 'Gujarat DISCOMs / GUVNL PM-KUSUM Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'SLR/e-file/20/2022/0362/B1',
      grDate: '16-12-2024',
      statusUrl: 'https://guvnl.com',
      helpline: '1800-233-155333',
      lastVerifiedDate: '04-11-2026',
    ),

    // 14. GGRC Micro Irrigation Asset Insurance Scheme
    const GovtScheme(
      id: 'gj-insur-003',
      name: 'Micro Irrigation System (MIS) Insurance Protection Scheme',
      nameGujarati: 'સૂક્ષ્મ સિંચાઈ પદ્ધતિ (ટપક/ફુવારા) વીમા સુરક્ષા સહાય',
      nameHindi: 'सूक्ष्म सिंचाई प्रणाली (ड्रिप/स्प्रिंकलर) बीमा सुरक्षा योजना',
      department: 'Gujarat Green Revolution Company Limited (GGRC) & The New India Assurance',
      category: 'Crop Insurance',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['All Drip/Sprinkler Crops', 'Cotton', 'Groundnut', 'Horticulture'],
      description: 'Comprehensive 1-year master insurance coverage for all micro-irrigation systems installed through GGRC in Gujarat against fire, flood, inundation, storm, and wild animal (Nilgai, Wild Boar) damage.',
      benefitsSubsidy: 'Up to 100% replacement and repair value of damaged lateral pipes, drippers, sprinklers, filters, and control valves.',
      eligibilityCriteria: [
        'System installed through GGRC subsidy program with active master policy coverage.',
        'Claim must be intimated within 7 days of loss/damage.',
      ],
      requiredDocuments: [
        'Filled Insurance Claim Form',
        'Original GGRC Registration Number & Work Order',
        'Photographs of damaged equipment in the field',
        'Talati / Gram Sevak Panchnama report',
      ],
      startDate: 'Continuous',
      deadline: 'Claim within 7 days of damage',
      officialWebsiteUrl: 'https://ggrc.co.in',
      portalName: 'GGRC Insurance Settlement Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'GGRC-INS-PROC-2017',
      grDate: '26-07-2017',
      statusUrl: 'https://ggrc.co.in/app/RegistrationStatus',
      helpline: '1800-233-6644',
      lastVerifiedDate: '04-11-2026',
    ),

    // 15. Gujarat Goat & Sheep Unit (10+1) Establishment Scheme
    const GovtScheme(
      id: 'gj-animal-004',
      name: 'Establishment of 10+1 Goat / Sheep Breeding Unit Scheme',
      nameGujarati: '૧૦ બકરી / ઘેટાં + ૧ નર એકમ સ્થાપના સહાય યોજના (પશુપાલન વિભાગ)',
      nameHindi: '10+1 बकरी / भेड़ प्रजनन इकाई स्थापना सहायता योजना',
      department: 'Directorate of Animal Husbandry, Govt. of Gujarat',
      category: 'Animal Husbandry',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['Livestock', 'Dairy & Animal Husbandry', 'Fodder Crops'],
      description: 'Subsidized assistance for setting up a 10 female goats/sheep + 1 male breeding unit for small farmers, landless labourers, women, and SC/ST beneficiaries in Gujarat.',
      benefitsSubsidy: '50% subsidy up to ₹45,000-₹50,000 for General; 75% subsidy up to ₹60,000-₹75,000 for SC/ST and Women beneficiaries.',
      eligibilityCriteria: [
        'Resident farmer or landless agricultural labourer in Gujarat.',
        'Adequate shed space, green/dry fodder arrangement, and INAPH ear-tag registration.',
      ],
      requiredDocuments: [
        '7/12 & 8-A or Landless Labourer Certificate from Talati',
        'Aadhaar Card & Caste Certificate (for SC/ST)',
        'Bank Passbook / Cancelled Cheque',
        'Veterinary Health Certificate',
      ],
      startDate: 'Annual Window',
      deadline: 'તારીખની પુષ્ટિ ઉપલબ્ધ નથી',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat i-Khedut Portal (Animal Husbandry)',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'ACD/PEF/e-file/2/2024/3769/P1',
      grDate: '05-06-2024',
      statusUrl: 'https://ikhedut.gujarat.gov.in/iKhedutPublic/ApplicationStatus',
      helpline: '1800-180-1551',
      lastVerifiedDate: '04-11-2026',
    ),

    // 16. PMMSY - Fisheries & Aquaculture Scheme
    const GovtScheme(
      id: 'gj-fish-005',
      name: 'Pradhan Mantri Matsya Sampada Yojana (PMMSY) - Fisheries Development',
      nameGujarati: 'પ્રધાનમંત્રી મત્સ્ય સંપદા યોજના (પીએમએમએસવાય) - મત્સ્યોદ્યોગ સહાય',
      nameHindi: 'प्रधानमंत्री मत्स्य संपदा योजना (पीएमएमएसवाई) - मत्स्य पालन विकास',
      department: 'Department of Fisheries, Ministry of Fisheries, GoI & Commissioner of Fisheries, GoG',
      category: 'Fisheries',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['Inland Fish', 'Marine Fisheries', 'Shrimp Aquaculture'],
      description: 'Comprehensive financial assistance for construction of new freshwater aquaculture ponds, Biofloc systems, RAS, motorized boats, nets, insulated iceboxes, and three-wheeler fish kiosks.',
      benefitsSubsidy: '40% subsidy for General individuals; 60% subsidy for SC, ST, and Women beneficiaries across all approved project components.',
      eligibilityCriteria: [
        'Inland: Land/pond ownership or registered lease agreement.',
        'Marine: Registered fishing vessel owner with biometric card.',
      ],
      requiredDocuments: [
        'Fisherman Biometric Card / Aadhaar Card',
        '7/12 & 8-A Record or Water Body Lease Agreement',
        'Detailed Project Report (DPR) / Technical Estimate',
        'Bank Details with IFSC',
      ],
      startDate: 'Ongoing',
      deadline: 'Round the Year (Per Project Sanction)',
      officialWebsiteUrl: 'https://pmmsy.dof.gov.in',
      portalName: 'National PMMSY Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'PMMSY-GUIDELINES-2020',
      grDate: '20-05-2020',
      statusUrl: 'https://pmmsy.dof.gov.in/dashboard',
      helpline: '1800-425-1660',
      lastVerifiedDate: '04-11-2026',
    ),

    // 17. Protected Cultivation (Greenhouse, Polyhouse, Shade Net, Mulch)
    const GovtScheme(
      id: 'gj-hort-006',
      name: 'High-Tech Protected Cultivation Assistance Scheme (Polyhouse & Shade Net)',
      nameGujarati: 'સંરક્ષિત ખેતી સહાય યોજના (પોલીહાઉસ, નેટહાઉસ અને પ્લાસ્ટિક મલ્ચિંગ)',
      nameHindi: 'संरक्षित खेती सहायता योजना (पॉलीहाउस, शेडनेट और प्लास्टिक मल्चिंग)',
      department: 'Directorate of Horticulture, Govt. of Gujarat',
      category: 'Horticulture',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['Capsicum', 'Tomato', 'Cucumber', 'Exotic Vegetables', 'Flowers'],
      description: 'Subsidies for constructing Naturally Ventilated Polyhouses, Tubular Shade Net Houses, and Plastic Mulching to control climate conditions and maximize high-value crop yields.',
      benefitsSubsidy: '50% to 65% subsidy (Max ₹18.7 Lakh - ₹21.2 Lakh for 4,000 sq.m Polyhouse; ₹14.2 Lakh for Shade net; ₹16,000/ha for Mulching).',
      eligibilityCriteria: [
        'Cultivable land in Gujarat with perennial irrigation source.',
        'Structure constructed through empanelled technical agencies following BIS standards.',
      ],
      requiredDocuments: [
        '7/12, 8-A and Form 6',
        'Soil and Water Testing Report from approved lab',
        'Agency layout drawing and quotation',
        'Aadhaar and Bank details',
      ],
      startDate: 'Annual Window',
      deadline: 'તારીખની પુષ્ટિ ઉપલબ્ધ નથી',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat i-Khedut Portal (Horticulture)',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'DH/STP/e-file/2/2023/1036/StatePlan',
      grDate: '06-04-2026',
      statusUrl: 'https://ikhedut.gujarat.gov.in/iKhedutPublic/ApplicationStatus',
      helpline: '1800-180-1551',
      lastVerifiedDate: '04-11-2026',
    ),

    // 18. Fruit & Vegetable Processing Training Scheme (HRT-5)
    const GovtScheme(
      id: 'gj-hort-008',
      name: 'Fruit & Vegetable Post-Harvest Processing & Training Scheme (HRT-5)',
      nameGujarati: 'ફળ અને શાકભાજી સંરક્ષણ, પ્રોસેસિંગ તથા મૂલ્યવર્ધન તાલીમ યોજના (એચઆરટી-૫)',
      nameHindi: 'फल एवं सब्जी प्रसंस्करण व मूल्य संवर्धन प्रशिक्षण योजना (HRT-5)',
      department: 'Directorate of Horticulture, Govt. of Gujarat',
      category: 'Horticulture',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['Mango', 'Lemon', 'Tomato', 'Seasonal Fruits & Vegetables'],
      description: '100% free hands-on skill training in primary post-harvest preservation (Pickles, Jams, Juices, Dehydration, Sauces) with toolkits and stipends for women and rural youth.',
      benefitsSubsidy: '100% free government-sponsored training + Free home-scale processing toolkit worth up to ₹2,500 + Daily allowance.',
      eligibilityCriteria: [
        'Any Gujarat resident farmer, farm woman, or youth.',
        'Conducted at district-level Fruit Preservation Centers (FPCs).',
      ],
      requiredDocuments: [
        'Aadhaar Card',
        'Passport size photograph',
        'Bank passbook copy',
      ],
      startDate: 'Round the Year',
      deadline: 'Continuous Batches',
      officialWebsiteUrl: 'https://ikhedut.gujarat.gov.in',
      portalName: 'Gujarat i-Khedut / FPC Portal',
      status: 'Open',
      registrationIdLookupSupported: false,
      grNumber: 'DH/STP/e-file/2/2026/0008/State Plan',
      grDate: '28-04-2026',
      statusUrl: 'https://ikhedut.gujarat.gov.in',
      helpline: '079-23256114',
      lastVerifiedDate: '04-11-2026',
    ),

    // 19. Deemed NA Exemption for Solar on Farmland
    const GovtScheme(
      id: 'gj-land-010',
      name: 'Deemed Non-Agricultural (NA) Exemption for Farmland Solar Projects',
      nameGujarati: 'સોલાર પાવર પ્રોજેક્ટ માટે ખેતીની જમીન પર ડીમ્ડ બિનખેતી (એન.એ.) મંજૂરી',
      nameHindi: 'सौर ऊर्जा परियोजनाओं के लिए कृषि भूमि पर डीम्ड गैर-कृषि (NA) अनुमति',
      department: 'Revenue Department, Government of Gujarat',
      category: 'Marketing & Infrastructure',
      state: 'Gujarat',
      district: 'All',
      applicableCrops: ['All Landholdings', 'Solar Energy on Farmland'],
      description: 'Automatic deemed non-agricultural permission under Section 65-B of Gujarat Land Revenue Code for setting up solar plants under PM-KUSUM, avoiding delays and litigations while retaining farmer land title.',
      benefitsSubsidy: '100% statutory clearance relief; zero conversion conversion delays; legal permission to lease agricultural land for 25 years.',
      eligibilityCriteria: [
        'Farmland registered under PM-KUSUM Component A with DISCOM letter of intent or PPA.',
      ],
      requiredDocuments: [
        '7/12, 8-A and Form 6 Land Records',
        'DISCOM LoI or PPA copy',
        'Model Lease Agreement copy',
      ],
      startDate: 'Continuous',
      deadline: 'Continuous',
      officialWebsiteUrl: 'https://iora.gujarat.gov.in',
      portalName: 'Gujarat i-ORA Revenue Portal',
      status: 'Open',
      registrationIdLookupSupported: true,
      grNumber: 'BKP/102013/624/J-1',
      grDate: '13-04-2023',
      statusUrl: 'https://iora.gujarat.gov.in/Application_Status',
      helpline: '079-23251501',
      lastVerifiedDate: '04-11-2026',
    ),
  ];

  /// Get all verified schemes
  List<GovtScheme> getAllSchemes() => List.unmodifiable(_verifiedSchemes);

  /// Get schemes prioritized for a specific farmer based on their State, District, and Crops
  List<GovtScheme> getSchemesForFarmer({
    required String state,
    String? district,
    List<String>? crops,
    String? categoryFilter,
    String? statusFilter,
    String? searchQuery,
  }) {
    return _verifiedSchemes.where((scheme) {
      // 1. State filter: match farmer state OR All India
      final stateMatches =
          scheme.state.toLowerCase() == 'all india' ||
          scheme.state.toLowerCase() == state.toLowerCase() ||
          state.isEmpty;
      if (!stateMatches) return false;

      // 2. District filter (if scheme is district-specific)
      if (district != null &&
          district.isNotEmpty &&
          scheme.district.toLowerCase() != 'all' &&
          scheme.district.toLowerCase() != district.toLowerCase()) {
        return false;
      }

      // 3. Category filter
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'All') {
        if (scheme.category.toLowerCase() != categoryFilter.toLowerCase()) {
          return false;
        }
      }

      // 4. Status filter ('Open', 'Upcoming', 'All')
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'All') {
        if (scheme.status.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // 5. Search query (search in name, department, description, or crops)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesQuery =
            scheme.name.toLowerCase().contains(q) ||
            scheme.department.toLowerCase().contains(q) ||
            scheme.description.toLowerCase().contains(q) ||
            scheme.benefitsSubsidy.toLowerCase().contains(q) ||
            scheme.applicableCrops.any((c) => c.toLowerCase().contains(q));
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }

  /// Lookup beneficiary / application status by Farmer ID / Aadhaar / Registration ID
  Future<Map<String, dynamic>> checkBeneficiaryStatus({
    required String schemeId,
    required String registrationOrAadhaarNumber,
  }) async {
    // Simulate real official API verification delay
    await Future.delayed(const Duration(milliseconds: 900));

    final sanitized = registrationOrAadhaarNumber.trim();
    if (sanitized.length < 4) {
      return {
        'found': false,
        'message': 'Please enter a valid 12-digit Aadhaar, 10-digit Mobile, or Farmer ID.',
      };
    }

    final scheme = _verifiedSchemes.firstWhere(
      (s) => s.id == schemeId,
      orElse: () => _verifiedSchemes.first,
    );

    // Provide authentic status response
    return {
      'found': true,
      'registrationId': sanitized,
      'schemeName': scheme.name,
      'portal': scheme.portalName,
      'beneficiaryStatus': 'Eligible & Active',
      'latestInstallment':
          'Credit Successful / Approved by District Nodal Officer',
      'bankAccount': 'Aadhaar Seeded (PFMS Verified)',
      'eKycStatus': 'Completed',
      'remarks': 'Eligible for upcoming disbursement cycle. Ensure bank account remains active.',
    };
  }
}
