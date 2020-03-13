#!/usr/bin/env cwl-runner
#
# Example score submission file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: ['Rscript', '/beat-pd/scoring_code/BEAT-PD_Scoring_Code.R']

hints:
  DockerRequirement:
    dockerPull: philsnyder/beat-pd-scoring:latest

inputs:
  - id: inputfile
    type: File?
  - id: entity_type
    type: string
  - id: phenotype 
    type: string
  - id: write_output_to_file
    type: string
    default: "results.json"
  - id: synapse_config
    type: File

arguments:
  - valueFrom: $(inputs.inputfile)
    prefix: --submission_file
  - valueFrom: $(inputs.entity_type)
    prefix: --entity_type
  - valueFrom: $(inputs.phenotype)
    prefix: --phenotype
  - valueFrom: $(inputs.write_output_to_file)
    prefix: --output_file
  - valueFrom: $(inputs.synapse_config.path)
    prefix: --synapse_config

outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json
