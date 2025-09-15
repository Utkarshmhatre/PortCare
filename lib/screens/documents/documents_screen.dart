import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/tokens.dart';
import '../../models/document.dart';
import '../../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _searchQuery = '';
  DocumentType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final documents = await _documentService.getUserDocuments(
        type: _selectedFilter,
        limit: 100,
      );
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
      }
    }
  }

  Future<void> _uploadDocuments() async {
    setState(() => _isUploading = true);

    try {
      print('Starting document upload...');
      final files = await _documentService.pickFiles();
      print('Files picked: ${files?.length ?? 0}');

      if (files == null || files.isEmpty) {
        print('No files selected');
        setState(() => _isUploading = false);
        return;
      }

      for (final file in files) {
        print('Processing file: ${file.name}');
        await _showDocumentDetailsDialog(file);
      }

      await _loadDocuments(); // Refresh the list
      print('Document upload completed');
    } catch (e) {
      print('Error uploading documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading documents: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showDocumentDetailsDialog(PlatformFile file) async {
    DocumentType selectedType = DocumentType.other;
    String? notes;
    bool encrypt = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Upload Document',
            style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File: ${file.name}',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Size: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: AppTypography.bodySmallStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                Text(
                  'Document Type',
                  style: AppTypography.bodyLargeStyle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<DocumentType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                    contentPadding: AppSpacing.mdAll,
                  ),
                  items: DocumentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                SizedBox(height: AppSpacing.md),

                TextField(
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                    contentPadding: AppSpacing.mdAll,
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value.isNotEmpty ? value : null,
                ),
                SizedBox(height: AppSpacing.md),

                CheckboxListTile(
                  title: Text(
                    'Encrypt document',
                    style: AppTypography.bodyLargeStyle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Adds additional security for sensitive documents',
                    style: AppTypography.bodySmallStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: encrypt,
                  onChanged: (value) {
                    setDialogState(() => encrypt = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyLargeStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _uploadDocument(file, selectedType, notes, encrypt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(
    PlatformFile file,
    DocumentType type,
    String? notes,
    bool encrypt,
  ) async {
    try {
      await _documentService.uploadDocument(
        file: file,
        type: type,
        notes: notes,
        encrypt: encrypt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Document',
          style: AppTypography.h2Style.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${document.name}"? This action cannot be undone.',
          style: AppTypography.bodyLargeStyle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.bodyLargeStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _documentService.deleteDocument(document);
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting document: $e')),
          );
        }
      }
    }
  }

  List<Document> get _filteredDocuments {
    return _documents.where((doc) {
      if (_searchQuery.isNotEmpty &&
          !doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !(doc.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false)) {
        return false;
      }
      if (_selectedFilter != null && doc.type != _selectedFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Documents',
          style: AppTypography.h1Style.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Search and Filter
                  Container(
                    color: AppColors.surface,
                    padding: AppSpacing.mdAll,
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search documents...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdRadius,
                            ),
                            contentPadding: AppSpacing.mdVertical,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Filter Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<DocumentType?>(
                                value: _selectedFilter,
                                decoration: InputDecoration(
                                  labelText: 'Filter by type',
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.mdRadius,
                                  ),
                                  contentPadding: AppSpacing.mdAll,
                                ),
                                items: [
                                  DropdownMenuItem<DocumentType?>(
                                    value: null,
                                    child: Text('All Types'),
                                  ),
                                  ...DocumentType.values.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type.displayName),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedFilter = value);
                                },
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading
                                      ? null
                                      : _uploadDocuments,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.mdRadius,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                  ),
                                  icon: _isUploading
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.surface,
                                                ),
                                          ),
                                        )
                                      : Icon(Icons.upload_file, size: 16),
                                  label: Text(
                                    'Upload',
                                    style: AppTypography.bodyLargeStyle
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Documents List
                  Expanded(
                    child: _filteredDocuments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  _documents.isEmpty
                                      ? 'No documents uploaded yet'
                                      : 'No documents match your search',
                                  style: AppTypography.bodyLargeStyle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (_documents.isEmpty) ...[
                                  SizedBox(height: AppSpacing.md),
                                  ElevatedButton.icon(
                                    onPressed: _isUploading
                                        ? null
                                        : _uploadDocuments,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.mdRadius,
                                      ),
                                      padding: AppSpacing.mdAll,
                                    ),
                                    icon: Icon(Icons.upload_file, size: 20),
                                    label: Text(
                                      'Upload Your First Document',
                                      style: AppTypography.bodyLargeStyle
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.surface,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: AppSpacing.mdAll,
                            itemCount: _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              return _buildDocumentCard(
                                _filteredDocuments[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        boxShadow: AppElevation.low,
      ),
      child: ListTile(
        contentPadding: AppSpacing.mdAll,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getDocumentTypeColor(document.type).withOpacity(0.1),
            borderRadius: AppRadius.smRadius,
          ),
          child: Icon(
            _getDocumentTypeIcon(document.type),
            color: _getDocumentTypeColor(document.type),
            size: 24,
          ),
        ),
        title: Text(
          document.name,
          style: AppTypography.bodyLargeStyle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.type.displayName,
              style: AppTypography.bodySmallStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(document.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB • ${_formatDate(document.createdAt)}',
              style: AppTypography.captionStyle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            if (document.description != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                document.description!,
                style: AppTypography.bodySmallStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document.isEncrypted)
              Icon(Icons.lock, size: 16, color: AppColors.textTertiary),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteDocument(document);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.danger, size: 16),
                      SizedBox(width: AppSpacing.sm),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return Icons.medication;
      case DocumentType.labReport:
        return Icons.science;
      case DocumentType.xray:
      case DocumentType.mri:
      case DocumentType.ct:
        return Icons.medical_services;
      case DocumentType.insurance:
        return Icons.security;
      case DocumentType.vaccination:
        return Icons.vaccines;
      default:
        return Icons.description;
    }
  }

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.prescription:
        return AppColors.accentBlue;
      case DocumentType.labReport:
        return AppColors.accentGreen;
      case DocumentType.xray:
      case DocumentType.mri:
      case DocumentType.ct:
        return AppColors.danger;
      case DocumentType.insurance:
        return AppColors.primary;
      case DocumentType.vaccination:
        return AppColors.accentGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
