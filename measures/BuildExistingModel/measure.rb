# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

# in addition to the above requires, this measure is expected to run in an
# environment with resstock/resources/buildstock.rb loaded

# start the measure
class BuildExistingModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Build Existing Model'
  end

  # human readable description
  def description
    return 'Builds the OpenStudio Model for an existing building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Builds the OpenStudio Model using the sampling csv file, which contains the specified parameters for each existing building. Based on the supplied building number, those parameters are used to run the OpenStudio measures with appropriate arguments and build up the OpenStudio model.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('buildstock_csv_path', true)
    arg.setDisplayName('Buildstock CSV File Path')
    arg.setDescription('Absolute/relative path of the buildstock CSV file, relative is compared to the lib/housing_characteristics_dir.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('building_id', true)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('number_of_buildings_represented', false)
    arg.setDisplayName('Number of Buildings Represented')
    arg.setDescription('The total number of buildings represented by the existing building models.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeDoubleArgument('sample_weight', false)
    arg.setDisplayName('Sample Weight of Simulation')
    arg.setDescription('Number of buildings this simulation represents.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('downselect_logic', false)
    arg.setDisplayName('Downselect Logic')
    arg.setDescription("Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_timestep', false)
    arg.setDisplayName('Simulation Control: Timestep')
    arg.setUnits('min')
    arg.setDescription('Value must be a divisor of 60.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_calendar_year', false)
    arg.setDisplayName('Simulation Control: Run Period Calendar Year')
    arg.setUnits('year')
    arg.setDescription('This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('os_hescore_directory', false)
    arg.setDisplayName('HEScore Workflow: OpenStudio-HEScore directory path')
    arg.setDescription('Path to the OpenStudio-HEScore directory. If specified, the HEScore workflow will run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_scenario_names', false)
    arg.setDisplayName('Emissions: Scenario Names')
    arg.setDescription('Names of emissions scenarios. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_types', false)
    arg.setDisplayName('Emissions: Types')
    arg.setDescription('Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_electricity_folders', false)
    arg.setDisplayName('Emissions: Electricity Folders')
    arg.setDescription('Relative paths of electricity emissions factor schedule files with hourly values. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. File names must contain GEA region names.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_natural_gas_values', false)
    arg.setDisplayName('Emissions: Natural Gas Values')
    arg.setDescription('Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_propane_values', false)
    arg.setDisplayName('Emissions: Propane Values')
    arg.setDescription('Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_fuel_oil_values', false)
    arg.setDisplayName('Emissions: Fuel Oil Values')
    arg.setDescription('Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_wood_values', false)
    arg.setDisplayName('Emissions: Wood Values')
    arg.setDescription('Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_scenario_names', false)
    arg.setDisplayName('Utility Bills: Scenario Names')
    arg.setDescription('Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_filepaths', false)
    arg.setDisplayName('Utility Bills: Electricity File Paths')
    arg.setDescription('Electricity tariff file specified as an absolute/relative path to a file with utility rate structure information. Tariff file must be formatted to OpenEI API version 7. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_simple_filepaths', false)
    arg.setDisplayName('Utility Bills: Simple Filepaths')
    arg.setDescription('Relative paths of simple utility rates. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. File names must contain State in the name.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Electricity Fixed Charges')
    arg.setDescription('Electricity utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_electricity_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Electricity Marginal Rates')
    arg.setDescription('Electricity utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_natural_gas_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Natural Gas Fixed Charges')
    arg.setDescription('Natural gas utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_natural_gas_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Natural Gas Marginal Rates')
    arg.setDescription('Natural gas utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_propane_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Propane Fixed Charges')
    arg.setDescription('Propane utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_propane_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Propane Marginal Rates')
    arg.setDescription('Propane utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_fuel_oil_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Fuel Oil Fixed Charges')
    arg.setDescription('Fuel oil utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_fuel_oil_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Fuel Oil Marginal Rates')
    arg.setDescription('Fuel oil utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_wood_fixed_charges', false)
    arg.setDisplayName('Utility Bills: Wood Fixed Charges')
    arg.setDescription('Wood utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_wood_marginal_rates', false)
    arg.setDisplayName('Utility Bills: Wood Marginal Rates')
    arg.setDescription('Wood utility bill marginal rates. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_compensation_types', false)
    arg.setDisplayName('Utility Bills: PV Compensation Types')
    arg.setDescription('Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rate_types', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rate Types')
    arg.setDescription("Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is 'NetMetering'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_net_metering_annual_excess_sellback_rates', false)
    arg.setDisplayName('Utility Bills: PV Net Metering Annual Excess Sellback Rates')
    arg.setDescription("Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is 'NetMetering' and the PV annual excess sellback rate type is 'User-Specified'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_feed_in_tariff_rates', false)
    arg.setDisplayName('Utility Bills: PV Feed-In Tariff Rates')
    arg.setDescription("Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is 'FeedInTariff'. If multiple scenarios, use a comma-separated list.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_monthly_grid_connection_fee_units', false)
    arg.setDisplayName('Utility Bills: PV Monthly Grid Connection Fee Units')
    arg.setDescription('Utility bill PV monthly grid connection fee units. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('utility_bill_pv_monthly_grid_connection_fees', false)
    arg.setDisplayName('Utility Bills: PV Monthly Grid Connection Fees')
    arg.setDescription('Utility bill PV monthly grid connection fees. If multiple scenarios, use a comma-separated list.')
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(model), user_arguments)

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources'))
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/housing_characteristics'))
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    measures_dir = File.join(File.dirname(__FILE__), '../../measures')
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')

    buildstock_csv_path = args['buildstock_csv_path']
    unless (Pathname.new buildstock_csv_path).absolute?
      buildstock_csv_path = File.absolute_path(File.join(characteristics_dir, buildstock_csv_path)) # Should have been generated by the Worker Initialization Script (run_sampling.rb) or provided by the project
    end

    if args['os_hescore_directory'].is_initialized
      os_hescore_directory = args['os_hescore_directory'].get
      hes_ruleset_measures_dir = File.join(os_hescore_directory, 'rulesets')
      run_hescore_workflow = true
    end

    # Load buildstock_file
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    Version.check_buildstockbatch_version()

    # Check file/dir paths exist
    check_dir_exists(resources_dir, runner)
    [measures_dir, hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end
    check_dir_exists(characteristics_dir, runner)
    check_file_exists(lookup_file, runner)
    check_file_exists(buildstock_csv_path, runner)

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    # Retrieve all data associated with sample number
    bldg_data = get_data_for_sample(buildstock_csv_path, args['building_id'], runner)

    # Retrieve order of parameters to run
    parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir)

    # Check buildstock.csv has all parameters
    missings = parameters_ordered - bldg_data.keys
    if !missings.empty?
      runner.registerError("Mismatch between buildstock.csv and options_lookup.tsv. Missing parameters: #{missings.join(', ')}.")
      return false
    end

    # Check buildstock.csv doesn't have extra parameters
    extras = bldg_data.keys - parameters_ordered - ['Building']
    if !extras.empty?
      runner.registerError("Mismatch between buildstock.csv and options_lookup.tsv. Extra parameters: #{extras.join(', ')}.")
      return false
    end

    # Retrieve options that have been selected for this building_id
    parameters_ordered.each do |parameter_name|
      # Register the option chosen for parameter_name with the runner
      option_name = bldg_data[parameter_name]
      register_value(runner, parameter_name, option_name)
    end

    # Determine whether this building_id has been downselected based on the
    # {parameter_name: option_name} pairs
    if args['downselect_logic'].is_initialized

      downselect_logic = args['downselect_logic'].get
      downselect_logic = downselect_logic.strip
      downselected = evaluate_logic(downselect_logic, runner, false)

      if downselected.nil?
        # unable to evaluate logic
        return false
      end

      unless downselected
        # Not in downselection; don't run existing home simulation
        runner.registerInfo('Sample is not in downselected parameters; will be registered as invalid.')
        runner.haltWorkflow('Invalid')
        return false
      end

    end

    # Obtain measures and arguments to be called
    measures = {}
    parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      print_option_assignment(parameter_name, option_name, runner)
      options_measure_args = get_measure_args_from_option_names(lookup_csv_data, [option_name], parameter_name, lookup_file, runner)
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash, false)
      end
    end

    # Get the absolute paths relative to this meta measure in the run directory
    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    if not apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
      register_logs(runner, new_runner)
      return false
    end

    # Initialize measure keys with hpxml_path arguments
    hpxml_path = File.expand_path('../existing.xml')
    measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => hpxml_path }]
    measures['BuildResidentialScheduleFile'] = [{ 'hpxml_path' => hpxml_path, 'hpxml_output_path' => hpxml_path }]

    new_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next if value == ''

      measures['BuildResidentialHPXML'][0][step_value.name] = value
    end

    # Set additional properties
    additional_properties = []
    ['ceiling_insulation_r'].each do |arg_name|
      arg_value = measures['ResStockArguments'][0][arg_name]
      additional_properties << "#{arg_name}=#{arg_value}"
    end
    measures['BuildResidentialHPXML'][0]['additional_properties'] = additional_properties.join('|') unless additional_properties.empty?

    # Get software program used and version
    measures['BuildResidentialHPXML'][0]['software_info_program_used'] = 'ResStock'
    measures['BuildResidentialHPXML'][0]['software_info_program_version'] = Version::ResStock_Version

    # Get registered values and pass them to BuildResidentialHPXML
    measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = args['simulation_control_timestep'].get if args['simulation_control_timestep'].is_initialized
    if args['simulation_control_run_period_begin_month'].is_initialized && args['simulation_control_run_period_begin_day_of_month'].is_initialized && args['simulation_control_run_period_end_month'].is_initialized && args['simulation_control_run_period_end_day_of_month'].is_initialized
      begin_month = "#{Date::ABBR_MONTHNAMES[args['simulation_control_run_period_begin_month'].get]}"
      begin_day = args['simulation_control_run_period_begin_day_of_month'].get
      end_month = "#{Date::ABBR_MONTHNAMES[args['simulation_control_run_period_end_month'].get]}"
      end_day = args['simulation_control_run_period_end_day_of_month'].get
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period'] = "#{begin_month} #{begin_day} - #{end_month} #{end_day}"
    end
    measures['BuildResidentialHPXML'][0]['simulation_control_run_period_calendar_year'] = args['simulation_control_run_period_calendar_year'].get if args['simulation_control_run_period_calendar_year'].is_initialized

    # Emissions
    if args['emissions_scenario_names'].is_initialized
      if !bldg_data.keys.include?('Generation And Emissions Assessment Region')
        runner.registerError('Emissions scenario(s) were specified, but could not find the Generation and Emissions Assessment (GEA) region.')
        return false
      end

      emissions_electricity_filepaths = []
      scenarios = args['emissions_electricity_folders'].get.split(',')
      scenarios.each do |scenario|
        scenario = File.join(resources_dir, scenario)
        if !File.exist?(scenario)
          runner.registerError("Emissions scenario electricity folder '#{scenario}' does not exist.")
          return false
        end

        Dir["#{scenario}/*.csv"].each do |filepath|
          emissions_electricity_filepaths << filepath if filepath.include?(bldg_data['Generation And Emissions Assessment Region'])
        end
      end

      emissions_scenario_names = args['emissions_scenario_names'].get
      emissions_types = args['emissions_types'].get
      emissions_electricity_filepaths = emissions_electricity_filepaths.join(',')
      emissions_electricity_units = ([HPXML::EmissionsScenario::UnitsKgPerMWh] * scenarios.size).join(',')

      measures['BuildResidentialHPXML'][0]['emissions_scenario_names'] = emissions_scenario_names
      measures['BuildResidentialHPXML'][0]['emissions_types'] = emissions_types
      measures['BuildResidentialHPXML'][0]['emissions_electricity_units'] = emissions_electricity_units
      measures['BuildResidentialHPXML'][0]['emissions_electricity_values_or_filepaths'] = emissions_electricity_filepaths
      register_value(runner, 'emissions_scenario_names', emissions_scenario_names)
      register_value(runner, 'emissions_types', emissions_types)
      register_value(runner, 'emissions_electricity_units', emissions_electricity_units)
      register_value(runner, 'emissions_electricity_values_or_filepaths', emissions_electricity_filepaths)

      emissions_fossil_fuel_units = ([HPXML::EmissionsScenario::UnitsLbPerMBtu] * scenarios.size).join(',')
      measures['BuildResidentialHPXML'][0]['emissions_fossil_fuel_units'] = emissions_fossil_fuel_units
      register_value(runner, 'emissions_fossil_fuel_units', emissions_fossil_fuel_units)

      emissions_natural_gas_values = args['emissions_natural_gas_values'].get
      measures['BuildResidentialHPXML'][0]['emissions_natural_gas_values'] = emissions_natural_gas_values
      register_value(runner, 'emissions_natural_gas_values', emissions_natural_gas_values)

      emissions_propane_values = args['emissions_propane_values'].get
      measures['BuildResidentialHPXML'][0]['emissions_propane_values'] = emissions_propane_values
      register_value(runner, 'emissions_propane_values', emissions_propane_values)

      emissions_fuel_oil_values = args['emissions_fuel_oil_values'].get
      measures['BuildResidentialHPXML'][0]['emissions_fuel_oil_values'] = emissions_fuel_oil_values
      register_value(runner, 'emissions_fuel_oil_values', emissions_fuel_oil_values)

      emissions_wood_values = args['emissions_wood_values'].get
      measures['BuildResidentialHPXML'][0]['emissions_wood_values'] = emissions_wood_values
      register_value(runner, 'emissions_wood_values', emissions_wood_values)
    end

    # Utility Bills
    if args['utility_bill_scenario_names'].is_initialized
      utility_bill_scenario_names = args['utility_bill_scenario_names'].get.split(',').map(&:strip)

      utility_bill_electricity_filepaths = args['utility_bill_electricity_filepaths'].get.split(',').map(&:strip)
      if utility_bill_electricity_filepaths.empty?
        utility_bill_electricity_filepaths = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_simple_filepaths = args['utility_bill_simple_filepaths'].get.split(',').map(&:strip)
      if utility_bill_simple_filepaths.empty?
        utility_bill_simple_filepaths = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_electricity_fixed_charges = args['utility_bill_electricity_fixed_charges'].get.split(',').map(&:strip)
      if utility_bill_electricity_fixed_charges.empty?
        utility_bill_electricity_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_electricity_marginal_rates = args['utility_bill_electricity_marginal_rates'].get.split(',').map(&:strip)
      if utility_bill_electricity_marginal_rates.empty?
        utility_bill_electricity_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_natural_gas_fixed_charges = args['utility_bill_natural_gas_fixed_charges'].get.split(',').map(&:strip)
      if utility_bill_natural_gas_fixed_charges.empty?
        utility_bill_natural_gas_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_natural_gas_marginal_rates = args['utility_bill_natural_gas_marginal_rates'].get.split(',').map(&:strip)
      if utility_bill_natural_gas_marginal_rates.empty?
        utility_bill_natural_gas_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_propane_fixed_charges = args['utility_bill_propane_fixed_charges'].get.split(',').map(&:strip)
      if utility_bill_propane_fixed_charges.empty?
        utility_bill_propane_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_propane_marginal_rates = args['utility_bill_propane_marginal_rates'].get.split(',').map(&:strip)
      if utility_bill_propane_marginal_rates.empty?
        utility_bill_propane_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_fuel_oil_fixed_charges = args['utility_bill_fuel_oil_fixed_charges'].get.split(',').map(&:strip)
      if utility_bill_fuel_oil_fixed_charges.empty?
        utility_bill_fuel_oil_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_fuel_oil_marginal_rates = args['utility_bill_fuel_oil_marginal_rates'].get.split(',').map(&:strip)
      if utility_bill_fuel_oil_marginal_rates.empty?
        utility_bill_fuel_oil_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_wood_fixed_charges = args['utility_bill_wood_fixed_charges'].get.split(',').map(&:strip)
      if utility_bill_wood_fixed_charges.empty?
        utility_bill_wood_fixed_charges = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_wood_marginal_rates = args['utility_bill_wood_marginal_rates'].get.split(',').map(&:strip)
      if utility_bill_wood_marginal_rates.empty?
        utility_bill_wood_marginal_rates = [nil] * utility_bill_scenario_names.size
      end

      utility_bill_scenarios = utility_bill_scenario_names.zip(utility_bill_electricity_filepaths,
                                                               utility_bill_simple_filepaths,
                                                               utility_bill_electricity_fixed_charges,
                                                               utility_bill_electricity_marginal_rates,
                                                               utility_bill_natural_gas_fixed_charges,
                                                               utility_bill_natural_gas_marginal_rates,
                                                               utility_bill_propane_fixed_charges,
                                                               utility_bill_propane_marginal_rates,
                                                               utility_bill_fuel_oil_fixed_charges,
                                                               utility_bill_fuel_oil_marginal_rates,
                                                               utility_bill_wood_fixed_charges,
                                                               utility_bill_wood_marginal_rates)

      utility_bill_electricity_filepaths = []
      utility_bill_electricity_fixed_charges = []
      utility_bill_electricity_marginal_rates = []
      utility_bill_natural_gas_fixed_charges = []
      utility_bill_natural_gas_marginal_rates = []
      utility_bill_propane_fixed_charges = []
      utility_bill_propane_marginal_rates = []
      utility_bill_fuel_oil_fixed_charges = []
      utility_bill_fuel_oil_marginal_rates = []
      utility_bill_wood_fixed_charges = []
      utility_bill_wood_marginal_rates = []
      utility_bill_scenarios.each do |utility_bill_scenario|
        _name, detail_filepath, simple_filepath, electricity_fixed_charge, electricity_marginal_rate, natural_gas_fixed_charge, natural_gas_marginal_rate, propane_fixed_charge, propane_marginal_rate, fuel_oil_fixed_charge, fuel_oil_marginal_rate, wood_fixed_charge, wood_marginal_rate = utility_bill_scenario

        if !simple_filepath.nil? && !simple_filepath.empty?
          simple_filepath = File.join(resources_dir, simple_filepath)
          if !File.exist?(simple_filepath)
            runner.registerError("Utility bill scenario file '#{simple_filepath}' does not exist.")
            return false
          end

          rows = CSV.read(simple_filepath, headers: true)
          utility_rates = rows.map { |d| d.to_hash }
          parameter = utility_rates[0].keys[0]

          if !bldg_data.keys.include?(parameter)
            runner.registerError("Utility bill scenario(s) were specified, but could not find #{parameter}.")
            return false
          end

          utility_rates = utility_rates.select { |r| r[parameter] == bldg_data[parameter] }

          if utility_rates.size != 1
            runner.registerWarning("Could not find #{parameter}=#{bldg_data[parameter]} in #{simple_filepath}.")
            utility_rate = Hash[rows.headers.map { |x| [x, nil] }]
          else
            utility_rate = utility_rates[0]
          end

          utility_bill_electricity_fixed_charges << utility_rate['electricity_fixed_charge']
          utility_bill_electricity_marginal_rates << utility_rate['electricity_marginal_rate']
          utility_bill_natural_gas_fixed_charges << utility_rate['natural_gas_fixed_charge']
          utility_bill_natural_gas_marginal_rates << utility_rate['natural_gas_marginal_rate']
          utility_bill_propane_fixed_charges << utility_rate['propane_fixed_charge']
          utility_bill_propane_marginal_rates << utility_rate['propane_marginal_rate']
          utility_bill_fuel_oil_fixed_charges << utility_rate['fuel_oil_fixed_charge']
          utility_bill_fuel_oil_marginal_rates << utility_rate['fuel_oil_marginal_rate']
          utility_bill_wood_fixed_charges << utility_rate['wood_fixed_charge']
          utility_bill_wood_marginal_rates << utility_rate['wood_marginal_rate']
        else
          if !detail_filepath.nil? && !detail_filepath.empty?
            detail_filepath = File.join(resources_dir, detail_filepath)
            if !File.exist?(detail_filepath)
              runner.registerError("Utility bill scenario file '#{detail_filepath}' does not exist.")
              return false
            end
          end
          utility_bill_electricity_filepaths << detail_filepath
          utility_bill_electricity_fixed_charges << electricity_fixed_charge
          utility_bill_electricity_marginal_rates << electricity_marginal_rate
          utility_bill_natural_gas_fixed_charges << natural_gas_fixed_charge
          utility_bill_natural_gas_marginal_rates << natural_gas_marginal_rate
          utility_bill_propane_fixed_charges << propane_fixed_charge
          utility_bill_propane_marginal_rates << propane_marginal_rate
          utility_bill_fuel_oil_fixed_charges << fuel_oil_fixed_charge
          utility_bill_fuel_oil_marginal_rates << fuel_oil_marginal_rate
          utility_bill_wood_fixed_charges << wood_fixed_charge
          utility_bill_wood_marginal_rates << wood_marginal_rate
        end
      end

      utility_bill_scenario_names = utility_bill_scenario_names.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_scenario_names'] = utility_bill_scenario_names
      register_value(runner, 'utility_bill_scenario_names', utility_bill_scenario_names)

      utility_bill_electricity_filepaths = utility_bill_electricity_filepaths.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_filepaths'] = utility_bill_electricity_filepaths
      register_value(runner, 'utility_bill_electricity_filepaths', utility_bill_electricity_filepaths)

      utility_bill_electricity_fixed_charges = utility_bill_electricity_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_fixed_charges'] = utility_bill_electricity_fixed_charges
      register_value(runner, 'utility_bill_electricity_fixed_charges', utility_bill_electricity_fixed_charges)

      utility_bill_electricity_marginal_rates = utility_bill_electricity_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_electricity_marginal_rates'] = utility_bill_electricity_marginal_rates
      register_value(runner, 'utility_bill_electricity_marginal_rates', utility_bill_electricity_marginal_rates)

      utility_bill_natural_gas_fixed_charges = utility_bill_natural_gas_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_fixed_charges'] = utility_bill_natural_gas_fixed_charges
      register_value(runner, 'utility_bill_natural_gas_fixed_charges', utility_bill_natural_gas_fixed_charges)

      utility_bill_natural_gas_marginal_rates = utility_bill_natural_gas_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_marginal_rates'] = utility_bill_natural_gas_marginal_rates
      register_value(runner, 'utility_bill_natural_gas_marginal_rates', utility_bill_natural_gas_marginal_rates)

      utility_bill_propane_fixed_charges = utility_bill_propane_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_propane_fixed_charges'] = utility_bill_propane_fixed_charges
      register_value(runner, 'utility_bill_propane_fixed_charges', utility_bill_propane_fixed_charges)

      utility_bill_propane_marginal_rates = utility_bill_propane_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_propane_marginal_rates'] = utility_bill_propane_marginal_rates
      register_value(runner, 'utility_bill_propane_marginal_rates', utility_bill_propane_marginal_rates)

      utility_bill_fuel_oil_fixed_charges = utility_bill_fuel_oil_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_fixed_charges'] = utility_bill_fuel_oil_fixed_charges
      register_value(runner, 'utility_bill_fuel_oil_fixed_charges', utility_bill_fuel_oil_fixed_charges)

      utility_bill_fuel_oil_marginal_rates = utility_bill_fuel_oil_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_marginal_rates'] = utility_bill_fuel_oil_marginal_rates
      register_value(runner, 'utility_bill_fuel_oil_marginal_rates', utility_bill_fuel_oil_marginal_rates)

      utility_bill_wood_fixed_charges = utility_bill_wood_fixed_charges.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_wood_fixed_charges'] = utility_bill_wood_fixed_charges
      register_value(runner, 'utility_bill_wood_fixed_charges', utility_bill_wood_fixed_charges)

      utility_bill_wood_marginal_rates = utility_bill_wood_marginal_rates.join(',')
      measures['BuildResidentialHPXML'][0]['utility_bill_wood_marginal_rates'] = utility_bill_wood_marginal_rates
      register_value(runner, 'utility_bill_wood_marginal_rates', utility_bill_wood_marginal_rates)

      utility_bill_pv_compensation_types = args['utility_bill_pv_compensation_types'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_compensation_types'] = utility_bill_pv_compensation_types
      register_value(runner, 'utility_bill_pv_compensation_types', utility_bill_pv_compensation_types)

      utility_bill_pv_net_metering_annual_excess_sellback_rate_types = args['utility_bill_pv_net_metering_annual_excess_sellback_rate_types'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rate_types'] = utility_bill_pv_net_metering_annual_excess_sellback_rate_types
      register_value(runner, 'utility_bill_pv_net_metering_annual_excess_sellback_rate_types', utility_bill_pv_net_metering_annual_excess_sellback_rate_types)

      utility_bill_pv_net_metering_annual_excess_sellback_rates = args['utility_bill_pv_net_metering_annual_excess_sellback_rates'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rates'] = utility_bill_pv_net_metering_annual_excess_sellback_rates
      register_value(runner, 'utility_bill_pv_net_metering_annual_excess_sellback_rates', utility_bill_pv_net_metering_annual_excess_sellback_rates)

      utility_bill_pv_feed_in_tariff_rates = args['utility_bill_pv_feed_in_tariff_rates'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_feed_in_tariff_rates'] = utility_bill_pv_feed_in_tariff_rates
      register_value(runner, 'utility_bill_pv_feed_in_tariff_rates', utility_bill_pv_feed_in_tariff_rates)

      utility_bill_pv_monthly_grid_connection_fee_units = args['utility_bill_pv_monthly_grid_connection_fee_units'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fee_units'] = utility_bill_pv_monthly_grid_connection_fee_units
      register_value(runner, 'utility_bill_pv_monthly_grid_connection_fee_units', utility_bill_pv_monthly_grid_connection_fee_units)

      utility_bill_pv_monthly_grid_connection_fees = args['utility_bill_pv_monthly_grid_connection_fees'].get
      measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fees'] = utility_bill_pv_monthly_grid_connection_fees
      register_value(runner, 'utility_bill_pv_monthly_grid_connection_fees', utility_bill_pv_monthly_grid_connection_fees)
    end

    # Get registered values and pass them to BuildResidentialScheduleFile
    measures['BuildResidentialScheduleFile'][0]['schedules_random_seed'] = args['building_id']
    measures['BuildResidentialScheduleFile'][0]['output_csv_path'] = File.expand_path('../schedules.csv')

    # Specify measures to run
    measures['BuildResidentialHPXML'][0]['apply_defaults'] = true # for apply_hvac_sizing
    if run_hescore_workflow
      measures_hash = { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'] }
    else
      measures_hash = { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'], 'BuildResidentialScheduleFile' => measures['BuildResidentialScheduleFile'] }
    end

    if not apply_measures(hpxml_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', 'existing.osw')
      register_logs(runner, new_runner)
      return false
    end

    # Copy existing.xml to home.xml for downstream HPXMLtoOpenStudio
    # We need existing.xml (and not just home.xml) for UpgradeCosts
    in_path = File.expand_path('../home.xml')
    FileUtils.cp(hpxml_path, in_path)

    # Run HEScore Measures
    if run_hescore_workflow
      hes_json_path = File.expand_path('../hes.json')
      measures['HPXMLtoHEScore'] = [{ 'hpxml_path' => in_path, 'output_path' => hes_json_path }]
      measures['HEScoreRuleset'] = [{ 'json_path' => hes_json_path, 'hpxml_output_path' => in_path }]

      # HPXMLtoHEScore and HEScoreRuleset
      measures_hash = { 'HPXMLtoHEScore' => measures['HPXMLtoHEScore'], 'HEScoreRuleset' => measures['HEScoreRuleset'] }

      if not apply_measures(hes_ruleset_measures_dir, measures_hash, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure')
        register_logs(runner, new_runner)
        return false
      end
    end

    # Report some additional location and model characteristics
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    else
      runner.registerWarning("BuildExistingModel measure could not find '#{hpxml_path}'.")
      return true
    end

    epw_path = Location.get_epw_path(hpxml, hpxml_path)
    epw_file = OpenStudio::EpwFile.new(epw_path)
    register_value(runner, 'weather_file_city', epw_file.city)
    register_value(runner, 'weather_file_latitude', epw_file.latitude)
    register_value(runner, 'weather_file_longitude', epw_file.longitude)

    # Determine weight
    if args['number_of_buildings_represented'].is_initialized
      total_samples = nil
      runner.analysis[:analysis][:problem][:workflow].each do |wf|
        next if wf[:name] != 'build_existing_model'

        wf[:variables].each do |v|
          next if v[:argument][:name] != 'building_id'

          total_samples = v[:maximum].to_f
        end
      end
      if total_samples.nil?
        runner.registerError('Could not retrieve value for number_of_buildings_represented.')
        return false
      end
      weight = args['number_of_buildings_represented'].get / total_samples
      register_value(runner, 'weight', weight.to_s)
    end

    if args['sample_weight'].is_initialized
      register_value(runner, 'weight', args['sample_weight'].get.to_s)
    end

    return true
  end

  def register_logs(runner, new_runner)
    new_runner.result.warnings.each do |warning|
      runner.registerWarning(warning.logMessage)
    end
    new_runner.result.info.each do |info|
      runner.registerInfo(info.logMessage)
    end
    new_runner.result.errors.each do |error|
      runner.registerError(error.logMessage)
    end
    return
  end
end

# register the measure to be used by the application
BuildExistingModel.new.registerWithApplication
