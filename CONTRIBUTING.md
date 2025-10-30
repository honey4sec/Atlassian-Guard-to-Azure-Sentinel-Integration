# Contributing to Atlassian Guard to Azure Sentinel Integration

Thank you for your interest in contributing to this project! We welcome contributions from the community.

## How to Contribute

### Reporting Issues

If you encounter a bug or have a feature request:

1. Check the [Issues](https://github.com/yourusername/atlassian-guard-sentinel/issues) page to see if it's already reported
2. If not, create a new issue with:
   - Clear, descriptive title
   - Detailed description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Azure region and Logic App version
   - Relevant logs or error messages

### Submitting Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/atlassian-guard-sentinel.git
   cd atlassian-guard-sentinel
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Update documentation as needed
   - Test your changes thoroughly

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include testing evidence

## Development Guidelines

### Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow Azure Logic App best practices
- Keep JSON files properly formatted

### Testing

Before submitting a PR, ensure:

1. **Logic App Deployment**: Test that the Logic App deploys successfully
2. **Webhook Functionality**: Verify webhook receives and processes test payloads
3. **Data Ingestion**: Confirm data appears in Log Analytics
4. **Error Handling**: Test various failure scenarios
5. **Documentation**: Ensure README is updated with any new steps

### Testing Checklist

- [ ] Clean deployment on new Azure subscription
- [ ] Webhook receives and validates tokens correctly
- [ ] JSON parsing handles all expected fields
- [ ] Data successfully ingests to Log Analytics
- [ ] Managed Identity permissions work correctly
- [ ] Error scenarios are handled gracefully
- [ ] Documentation is accurate and complete

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the version number in any relevant files
3. Your PR will be reviewed by maintainers
4. Address any feedback or requested changes
5. Once approved, your PR will be merged

## Areas for Contribution

We especially welcome contributions in these areas:

### High Priority
- Additional alert type support
- Enhanced error handling and retry logic
- Performance optimizations
- Multi-region deployment templates
- Terraform/Bicep Infrastructure as Code templates

### Medium Priority
- Additional data transformations
- Custom KQL queries for Sentinel
- Automated testing scripts
- CI/CD pipeline configurations
- Monitoring and alerting templates

### Documentation
- Video tutorials
- Architecture diagrams
- Troubleshooting guides
- Integration examples
- FAQ section

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Review closed issues for similar questions
3. Open a new issue with the "question" label
4. Join our discussions (if applicable)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome diverse perspectives
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or personal attacks
- Public or private harassment
- Publishing others' private information
- Other unprofessional conduct

## Recognition

Contributors will be recognized in the project README and release notes.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
