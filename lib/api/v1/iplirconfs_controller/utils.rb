module Api::V1::IplirconfsController::Utils
  def prepare(params)
    unless params[:file] && params[:coord_vid]
      Rails.logger.error("Incorrect params #{params}")
      return nil
    end

    iplirconf_content = File.read(params[:file].tempfile)
    current_iplirconf = VipnetParser::Iplirconf.new(iplirconf_content)
    current_iplirconf.parse

    network_vid = VipnetParser.network(params[:coord_vid])
    network = Network.find_or_create_by(network_vid: network_vid)
    coordinator = Coordinator.find_or_create_by(
      vid: params[:coord_vid],
      network: network,
    )

    # Initialize "previous_iplirconf_version" variable for "coordinator".
    coordinator.current_iplirconf_version ||= current_iplirconf.version
    coordinator.save! if coordinator.changed?

    # Considering "coordinator.current_iplirconf_version" to be previous version,
    # and "current_iplirconf"'s to be current.
    previous_iplirconf_version = coordinator.current_iplirconf_version

    garland_diff = Iplirconf.push(
      hash: current_iplirconf.hash,
      belongs_to: coordinator,
    )
    unless garland_diff
      Rails.logger.error("Unable to push hash")
      return nil
    end
    iplirconf_created_at = garland_diff.created_at

    # Getting appropriate diff.
    if current_iplirconf.version == previous_iplirconf_version
      diff = garland_diff.safe_eval_entity
    else
      unless current_iplirconf.downgrade(previous_iplirconf_version)
        Rails.logger.info("Falied to downgrade current_iplirconf")
        return nil
      end

      previous_snapshot = Iplirconf
                            .head(coordinator)
                            .previous
                            .previous
                            .snapshot
      previous_iplirconf_hash = previous_snapshot.safe_eval_entity

      diff = HashDiffSym.diff(previous_iplirconf_hash, current_iplirconf.hash)
    end
    coordinator.update_attributes(
      current_iplirconf_version: current_iplirconf.version,
    )

    [coordinator, iplirconf_created_at, diff]
  end

  module_function :prepare
end
