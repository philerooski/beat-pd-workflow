#!/usr/bin/env cwl-runner
#
# Set permissions.
# This tool was created so that download permissions can be set
# on the log folder of the submission given to the admin team.
# When the challenge is run by a service account, only the service account
# has access to the log folder.
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: challengeutils

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/challengeutils:develop

inputs:
  - id: entityid
    type: string
  - id: principalid
    type: string
  - id: permissions
    type: string
  - id: synapse_config
    type: File

arguments:
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: setentityacl
  - valueFrom: $(inputs.entityid)
  - valueFrom: $(inputs.principalid)
  - valueFrom: $(inputs.permissions)

outputs: []
