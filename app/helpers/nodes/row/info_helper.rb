module Nodes::Row::InfoHelper
  def info_order
      %i[
        name
        vid
        network
        enabled
        category
        ip
        accessip
        version
        version_decoded
        creation_date
        deletion_date
        mftp_server
        clients_registered
        ncc
        ticket
      ]
    end
end
