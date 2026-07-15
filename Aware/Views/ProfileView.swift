import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Profile tab

struct ProfileView: View {
    let profile: UserProfile

    @Query private var habits: [Habit]
    @Query private var entries: [JournalEntry]
    @Query private var moods: [MoodEntry]

    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        AvatarView(profile: profile, size: 96)
                        Text(profile.name)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Color.appInk)
                        if !profile.email.isEmpty {
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    HStack(spacing: 12) {
                        statTile(value: habits.count, label: "Habits")
                        statTile(value: entries.count, label: "Journal entries")
                        statTile(value: moods.count, label: "Moods logged")
                    }

                    VStack(spacing: 0) {
                        infoRow(label: "Birthday", value: profile.birthday.formatted(date: .long, time: .omitted))
                        Divider().padding(.leading, 20)
                        infoRow(label: "Gender", value: profile.gender.rawValue)
                        Divider().padding(.leading, 20)
                        infoRow(label: "Member since", value: profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)

                    Button {
                        showEdit = true
                    } label: {
                        Text("Edit profile")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Aware 1.0 — be aware with yourself")
                        .font(.caption)
                        .foregroundStyle(Color.appMuted)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .sheet(isPresented: $showEdit) {
                NavigationStack {
                    ProfileFormView(profile: profile)
                }
            }
        }
    }

    private func statTile(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appAccent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.appMuted)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appInk)
        }
        .font(.subheadline)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Create / edit profile form

struct ProfileFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let profile: UserProfile?

    @State private var name: String
    @State private var email: String
    @State private var birthday: Date
    @State private var gender: Gender
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    init(profile: UserProfile? = nil) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _email = State(initialValue: profile?.email ?? "")
        _birthday = State(initialValue: profile?.birthday
            ?? Calendar.current.date(byAdding: .year, value: -18, to: .now)
            ?? .now)
        _gender = State(initialValue: profile?.gender ?? .other)
        _photoData = State(initialValue: profile?.photoData)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            photoPreview
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(Color.appAccent, in: Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose profile photo")
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("About you") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                DatePicker("Birthday", selection: $birthday, in: ...Date.now, displayedComponents: .date)
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
        }
        .navigationTitle(profile == nil ? "Create profile" : "Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if profile != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(profile == nil ? "Get started" : "Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: photoItem) { _, item in
            Task {
                if let item, let data = try? await item.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
    }

    private var photoPreview: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.appAccentSoft
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let profile {
            profile.name = trimmedName
            profile.email = trimmedEmail
            profile.birthday = birthday
            profile.gender = gender
            profile.photoData = photoData
        } else {
            context.insert(UserProfile(
                name: trimmedName,
                email: trimmedEmail,
                birthday: birthday,
                gender: gender,
                photoData: photoData
            ))
        }
        dismiss()
    }
}

// MARK: - Onboarding (first launch)

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.appAccentSoft)
                        .frame(width: 120, height: 120)
                    Circle()
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 10)
                        .frame(width: 88, height: 88)
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 34, height: 34)
                }
                .padding(.bottom, 12)
                .accessibilityHidden(true)

                Text("Aware")
                    .font(.system(size: 44, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.appInk)

                Text("Be aware with yourself.")
                    .font(.title3)
                    .foregroundStyle(Color.appMuted)

                Text("Track your habits, your moods, and the small moments that make up your days.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
                Spacer()

                NavigationLink {
                    ProfileFormView()
                } label: {
                    Text("Create your profile")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(28)
            .background(Color.appBackground)
        }
    }
}
