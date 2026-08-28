## Summary

<!-- Describe the change and why it is needed. -->

## Scope

<!-- List the workflows, hosts, or cluster resources affected. -->

## Validation

- [ ] `nix flake check`
- [ ] `terraform fmt -check -recursive`
- [ ] `terraform validate`
- [ ] Live cluster verification completed, if applicable
- [ ] Validation not run, with an explanation below

## Operational Impact

<!-- Describe changes to the Mac mini, Colima, k3s, Terraform state, or cluster resources. -->

## Checklist

- [ ] No Terraform state, kubeconfigs, credentials, or secrets are included
- [ ] `.terraform.lock.hcl` is committed when provider dependencies change
- [ ] Documentation reflects the new workflow or behavior
- [ ] The change stays within the intended milestone scope
