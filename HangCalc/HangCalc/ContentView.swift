import SwiftUI
import Combine

let WIRE_INDEX = AppConstants.WIRE_INDEX // Accessing a static constant
let D_RING_INDEX = AppConstants.D_RING_INDEX

// Professional Color Scheme
struct AppColors {
    static let primary = Color(red: 0.2, green: 0.4, blue: 0.8) // Professional blue
    static let secondary = Color(red: 0.9, green: 0.9, blue: 0.95) // Light gray-blue
    static let accent = Color(red: 0.8, green: 0.6, blue: 0.2) // Warm gold
    static let success = Color(red: 0.2, green: 0.7, blue: 0.3) // Green
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.1) // Orange
    static let error = Color(red: 0.8, green: 0.2, blue: 0.2) // Red
    static let background = Color(red: 0.98, green: 0.98, blue: 1.0) // Very light blue
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.2) // Dark blue-gray
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.5) // Medium gray
}

// Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.secondary)
            .foregroundColor(AppColors.textPrimary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Custom Text Field Style
struct ProfessionalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.secondary, lineWidth: 1)
            )
    }
}

// Section Header Component
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(AppColors.textPrimary)
            .padding(.bottom, 4)
    }
}

// Wall Dimensions Section
struct WallDimensionsSection: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        Section(header: SectionHeader(title: "Wall Dimensions (cm)")) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Width")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("300", text: $viewModel.wallWidth)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
                
                Text("×")
                    .font(.title2)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("244", text: $viewModel.wallHeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// Spacing Section
struct SpacingSection: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        Section(header: SectionHeader(title: "Spacing Between Paintings")) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spacing Mode")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Picker("Spacing Mode", selection: $viewModel.spacingMode) {
                        Text("Auto").tag(SpacingMode.auto)
                        Text("Manual").tag(SpacingMode.manual)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accentColor(AppColors.primary)
                }
                
                if viewModel.spacingMode == .manual {
                    ManualSpacingView(viewModel: viewModel)
                } else {
                    AutoSpacingView(viewModel: viewModel)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// Manual Spacing View
struct ManualSpacingView: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spacing (cm)")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                TextField("200", text: $viewModel.manualSpacing)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(ProfessionalTextFieldStyle())
            }
            
            // Validation message
            if let spacingValue = Double(viewModel.manualSpacing), spacingValue < 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.error)
                    Text("Spacing must be positive")
                        .font(.caption)
                        .foregroundColor(AppColors.error)
                }
            } else if let spacingValue = Double(viewModel.manualSpacing), let wall = viewModel.wall {
                let totalPaintingWidth = viewModel.paintings.reduce(0) { $0 + $1.width }
                let availableSpace = wall.width - totalPaintingWidth
                let requiredSpacing = availableSpace / CGFloat(viewModel.paintings.count - 1)
                
                if spacingValue > requiredSpacing {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.warning)
                        Text("Warning: Spacing too large for wall width")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
        }
    }
}

// Auto Spacing View
struct AutoSpacingView: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        if let wall = viewModel.wall {
            let autoSpacing = LayoutCalculator.calculateAutoSpacing(wall: wall, paintings: viewModel.paintings)
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
                Text("Auto spacing:")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                Text(String(format: "%.1f cm", autoSpacing))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

// Add Painting Section
struct AddPaintingSection: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        Section(header: SectionHeader(title: "Add Painting")) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Painting Name")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("e.g. Mona Lisa", text: $viewModel.newPaintingName)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width (cm)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("20", text: $viewModel.newPaintingWidth)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ProfessionalTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height (cm)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("25", text: $viewModel.newPaintingHeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ProfessionalTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mount Type")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Picker("Mount Type", selection: $viewModel.newMountTypeIndex) {
                        Text("D-Ring").tag(D_RING_INDEX)
                        Text("Wire").tag(WIRE_INDEX)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accentColor(AppColors.primary)
                }
                
                if viewModel.newMountTypeIndex == WIRE_INDEX {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offset from top of painting (cm)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("10", text: $viewModel.newWireOffset)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ProfessionalTextFieldStyle())
                    }
                } else if viewModel.newMountTypeIndex == D_RING_INDEX {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Offset from top of painting (cm)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("10", text: $viewModel.newDRingOffsetTop)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(ProfessionalTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Offset from edge to center of d-ring (cm)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            TextField("5", text: $viewModel.newDRingOffsetEdge)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(ProfessionalTextFieldStyle())
                        }
                    }
                }
                
                Button(action: {
                    guard
                        let w = Double(viewModel.newPaintingWidth), w > 0,
                        let h = Double(viewModel.newPaintingHeight), h > 0,
                        !viewModel.newPaintingName.isEmpty
                    else { return }

                    let mount: MountType
                    if viewModel.newMountTypeIndex == WIRE_INDEX {
                        guard let offset = Double(viewModel.newWireOffset), offset >= 0 else { return }
                        let offsetCGFloat: CGFloat = CGFloat(offset)
                        mount = .wire(offsetFromTop: offsetCGFloat)
                    } else {
                        guard
                            let offsetTop = Double(viewModel.newDRingOffsetTop), offsetTop >= 0,
                            let offsetEdge = Double(viewModel.newDRingOffsetEdge), offsetEdge >= 0
                        else { return }
                        let offsetTopCGFloat: CGFloat = CGFloat(offsetTop)
                        let offsetEdgeCGFloat: CGFloat = CGFloat(offsetEdge)
                        mount = .dRing(offsetFromTop: offsetTopCGFloat, offsetFromEdge: offsetEdgeCGFloat)
                    }

                    viewModel.paintings.append(Painting(name: viewModel.newPaintingName, width: CGFloat(w), height: CGFloat(h), mountType: mount))
                    viewModel.newPaintingName = ""
                    viewModel.newPaintingWidth = "20"
                    viewModel.newPaintingHeight = "25"
                    viewModel.newWireOffset = "10"
                    viewModel.newDRingOffsetTop = "10"
                    viewModel.newDRingOffsetEdge = "5"
                    viewModel.newMountTypeIndex = WIRE_INDEX // default to Wire
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Painting")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 16)
            }
        }
    }
}

// Paintings List Section
struct PaintingsListSection: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        Section(header: SectionHeader(title: "Paintings")) {
            ForEach(Array(viewModel.paintings.enumerated()), id: \.element.id) { index, painting in
                PaintingRowView(painting: painting, index: index, viewModel: viewModel)
            }
            .onDelete { idx in
                viewModel.paintings.remove(atOffsets: idx)
                // Reset spacing mode if we're back to single painting
                if viewModel.paintings.count == 1 {
                    viewModel.spacingMode = .auto
                }
            }
        }
    }
}

// Individual Painting Row View
struct PaintingRowView: View {
    let painting: Painting
    let index: Int
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 12) {
                PaintingInfoView(painting: painting)
                Spacer()
                MountTypeBadgeView(painting: painting)
                
                // Action buttons
                HStack(spacing: 8) {
                    // Duplicate button
                    Button(action: {
                        viewModel.duplicatePainting(at: index)
                    }) {
                        Image(systemName: "plus.square.on.square")
                            .foregroundColor(AppColors.primary)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Edit button
                    Button(action: {
                        viewModel.startEditingPainting(at: index)
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(AppColors.accent)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            
            // Edit form (shown when editing)
            if viewModel.editingPaintingIndex == index {
                EditPaintingForm(viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.secondary, lineWidth: 1)
        )
    }
}

// Edit Painting Form
struct EditPaintingForm: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            // Name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                TextField("Painting name", text: $viewModel.editPaintingName)
                    .textFieldStyle(ProfessionalTextFieldStyle())
            }
            
            // Dimensions
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Width (cm)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("20", text: $viewModel.editPaintingWidth)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height (cm)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("25", text: $viewModel.editPaintingHeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
            }
            
            // Mount type
            VStack(alignment: .leading, spacing: 8) {
                Text("Mount Type")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Picker("Mount Type", selection: $viewModel.editMountTypeIndex) {
                    Text("D-Ring").tag(D_RING_INDEX)
                    Text("Wire").tag(WIRE_INDEX)
                }
                .pickerStyle(SegmentedPickerStyle())
                .accentColor(AppColors.primary)
            }
            
            // Mount-specific fields
            if viewModel.editMountTypeIndex == WIRE_INDEX {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wire Offset from Top (cm)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("10", text: $viewModel.editWireOffset)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ProfessionalTextFieldStyle())
                }
            } else {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offset from Top (cm)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("10", text: $viewModel.editDRingOffsetTop)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ProfessionalTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offset from Edge (cm)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("10", text: $viewModel.editDRingOffsetEdge)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ProfessionalTextFieldStyle())
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.cancelEditing()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveEditedPainting()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// Painting Info View
struct PaintingInfoView: View {
    let painting: Painting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(painting.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            Text("\(Int(painting.width)) × \(Int(painting.height)) cm")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// Mount Type Badge View
struct MountTypeBadgeView: View {
    let painting: Painting
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: {
                switch painting.mountType {
                case .wire:
                    return "link"
                case .dRing:
                    return "circle.grid.2x2"
                }
            }())
                .foregroundColor(AppColors.accent)
                .font(.caption)
            Text({
                switch painting.mountType {
                case .wire:
                    return "Wire"
                case .dRing:
                    return "D-Ring"
                }
            }())
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.secondary.opacity(0.3))
        .cornerRadius(6)
    }
}

// Visualization Section
struct VisualizationSection: View {
    let wall: Wall
    let layouts: [PaintingLayout]
    let paintings: [Painting]
    let spacingMode: SpacingMode
    let manualSpacing: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with spacing summary
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(AppColors.primary)
                    Text("Visualization")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                
                // Spacing summary
                if paintings.count > 1 {
                    SpacingSummaryView(
                        spacingMode: spacingMode,
                        manualSpacing: manualSpacing,
                        wall: wall,
                        paintings: paintings
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Wall visualization - fill remaining space
            WallScrollView(wall: wall, layouts: layouts)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.secondary, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
}

// Spacing Summary View
struct SpacingSummaryView: View {
    let spacingMode: SpacingMode
    let manualSpacing: String
    let wall: Wall
    let paintings: [Painting]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: spacingMode == .auto ? "wand.and.stars" : "slider.horizontal.3")
                .foregroundColor(AppColors.accent)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Spacing Mode")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(spacingMode == .auto ? "Auto" : "Manual")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Current Spacing")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                if spacingMode == .manual {
                    Text("\(manualSpacing) cm")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    let autoSpacing = LayoutCalculator.calculateAutoSpacing(wall: wall, paintings: paintings)
                    Text("\(String(format: "%.1f", autoSpacing)) cm")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.secondary.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.secondary, lineWidth: 1)
        )
    }
}

enum SpacingMode {
    case auto
    case manual
}

// Main Form View
struct MainFormView: View {
    @ObservedObject var viewModel: HangCalcViewModel
    
    var body: some View {
        Form {
            WallDimensionsSection(viewModel: viewModel)
            
            if viewModel.paintings.count > 1 {
                SpacingSection(viewModel: viewModel)
            }
            
            AddPaintingSection(viewModel: viewModel)
            
            if !viewModel.paintings.isEmpty {
                PaintingsListSection(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.newMountTypeIndex = WIRE_INDEX // default to Wire
        }
    }
}

class HangCalcViewModel: ObservableObject {
    @Published var wallWidth: String = "300"
    @Published var wallHeight: String = "244"
    @Published var paintings: [Painting] = []
    @Published var newPaintingName: String = ""
    @Published var newPaintingWidth: String = "20"
    @Published var newPaintingHeight: String = "25"
    @Published var newMountTypeIndex: Int = WIRE_INDEX // 0 = D-Ring, 1 = Wire
    @Published var newWireOffset: String = "10"
    @Published var newDRingOffsetTop: String = "10"
    @Published var newDRingOffsetEdge: String = "10"
    @Published var spacingMode: SpacingMode = .auto
    @Published var manualSpacing: String = "200"
    
    // Edit state
    @Published var editingPaintingIndex: Int? = nil
    @Published var editPaintingName: String = ""
    @Published var editPaintingWidth: String = ""
    @Published var editPaintingHeight: String = ""
    @Published var editMountTypeIndex: Int = WIRE_INDEX
    @Published var editWireOffset: String = ""
    @Published var editDRingOffsetTop: String = ""
    @Published var editDRingOffsetEdge: String = ""
    
    var wall: Wall? {
        guard let w = Double(wallWidth), let h = Double(wallHeight),
              w > 0, h > 0 else {
            return nil
        }
        return Wall(width: CGFloat(w), height: CGFloat(h))
    }
    
    var layouts: [PaintingLayout] {
        guard let wall = wall else { return [] }
        let spacing: CGFloat
        if paintings.count == 1 {
            spacing = 200 // Default spacing for single painting
        } else if paintings.count > 1 {
            switch spacingMode {
            case .auto:
                spacing = LayoutCalculator.calculateAutoSpacing(wall: wall, paintings: paintings)
            case .manual:
                spacing = CGFloat(Double(manualSpacing) ?? 200)
            }
        } else {
            spacing = 200
        }
        return LayoutCalculator.calculateLayouts(wall: wall, paintings: paintings, spacing: spacing)
    }
    
    // Helper to check if wall dimensions are valid
    var isWallValid: Bool {
        return wall != nil
    }
    
    // Duplicate a painting
    func duplicatePainting(at index: Int) {
        guard index < paintings.count else { return }
        let original = paintings[index]
        let duplicate = Painting(
            name: "\(original.name) (Copy)",
            width: original.width,
            height: original.height,
            mountType: original.mountType
        )
        paintings.insert(duplicate, at: index + 1)
    }
    
    // Start editing a painting
    func startEditingPainting(at index: Int) {
        guard index < paintings.count else { return }
        let painting = paintings[index]
        
        editingPaintingIndex = index
        editPaintingName = painting.name
        editPaintingWidth = String(format: "%.0f", painting.width)
        editPaintingHeight = String(format: "%.0f", painting.height)
        
        switch painting.mountType {
        case .wire(let offset):
            editMountTypeIndex = WIRE_INDEX
            editWireOffset = String(format: "%.0f", offset)
        case .dRing(let offsetTop, let offsetEdge):
            editMountTypeIndex = D_RING_INDEX
            editDRingOffsetTop = String(format: "%.0f", offsetTop)
            editDRingOffsetEdge = String(format: "%.0f", offsetEdge)
        }
    }
    
    // Save edited painting
    func saveEditedPainting() {
        guard let index = editingPaintingIndex,
              let width = Double(editPaintingWidth), width > 0,
              let height = Double(editPaintingHeight), height > 0 else {
            return
        }
        
        let mount: MountType
        if editMountTypeIndex == WIRE_INDEX {
            guard let offset = Double(editWireOffset), offset >= 0 else { return }
            mount = .wire(offsetFromTop: CGFloat(offset))
        } else {
            guard let offsetTop = Double(editDRingOffsetTop), offsetTop >= 0,
                  let offsetEdge = Double(editDRingOffsetEdge), offsetEdge >= 0 else { return }
            mount = .dRing(offsetFromTop: CGFloat(offsetTop), offsetFromEdge: CGFloat(offsetEdge))
        }
        
        let updatedPainting = Painting(
            name: editPaintingName.isEmpty ? "Untitled" : editPaintingName,
            width: CGFloat(width),
            height: CGFloat(height),
            mountType: mount
        )
        
        paintings[index] = updatedPainting
        cancelEditing()
    }
    
    // Cancel editing
    func cancelEditing() {
        editingPaintingIndex = nil
        editPaintingName = ""
        editPaintingWidth = ""
        editPaintingHeight = ""
        editMountTypeIndex = WIRE_INDEX
        editWireOffset = ""
        editDRingOffsetTop = ""
        editDRingOffsetEdge = ""
    }
}

struct ContentView: View {
    @StateObject var viewModel = HangCalcViewModel()
    // Bottom sheet state
    @State private var sheetOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    // Sheet positions
    private var collapsedHeight: CGFloat { 220 }
    private var expandedHeight: CGFloat { UIScreen.main.bounds.height - 80 }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Main controls (painting list, add, etc)
                VStack(spacing: 0) {
                    // App title
                    Text("HangCalc")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    MainFormView(viewModel: viewModel)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, collapsedHeight)
                
                // Draggable visualization sheet - only show when wall is valid
                if let wall = viewModel.wall {
                    DraggableSheet(
                        offset: $sheetOffset,
                        collapsedHeight: collapsedHeight,
                        expandedHeight: expandedHeight
                    ) {
                        VisualizationSection(
                            wall: wall,
                            layouts: viewModel.layouts,
                            paintings: viewModel.paintings,
                            spacingMode: viewModel.spacingMode,
                            manualSpacing: viewModel.manualSpacing
                        )
                    }
                } else {
                    // Show placeholder when wall is invalid
                    DraggableSheet(
                        offset: $sheetOffset,
                        collapsedHeight: collapsedHeight,
                        expandedHeight: expandedHeight
                    ) {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.warning)
                            
                            Text("Invalid Wall Dimensions")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Please enter valid width and height values to see the visualization.")
                                .font(.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.background)
                        .cornerRadius(16)
                        .padding()
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .background(Color(UIColor.systemBackground))
        }
    }
}

// Draggable bottom sheet
struct DraggableSheet<Content: View>: View {
    @Binding var offset: CGFloat
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    let content: () -> Content
    
    @GestureState private var dragState: CGFloat = 0
    
    var body: some View {
        // Debug prints
        let totalHeight = max(0, expandedHeight - collapsedHeight)
        let currentOffset = max(0, min(offset + dragState, totalHeight))
        
        VStack(spacing: 0) {
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(Color.secondary.opacity(0.3))
                .padding(.top, 8)
                .padding(.bottom, 4)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BlurView(style: .systemMaterial))
        .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
        .shadow(radius: 8)
        .frame(height: collapsedHeight + totalHeight)
        .offset(y: totalHeight - currentOffset)
        .gesture(
            DragGesture()
                .updating($dragState) { value, state, _ in
                    state = -value.translation.height
                }
                .onEnded { value in
                    let drag = -value.translation.height
                    let threshold = totalHeight / 2
                    if offset + drag > threshold {
                        offset = totalHeight
                    } else {
                        offset = 0
                    }
                }
        )
        .animation(.interactiveSpring(), value: offset)
    }
}

// Blur background helper
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}



struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
