import SwiftUI
import SwiftData
import PhotosUI

struct JournalView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing here yet", systemImage: "book.closed")
                    } description: {
                        Text("Write what happened today — future you will love reading it.")
                    } actions: {
                        Button("Write an entry") { showNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            ForEach(groupedByDay, id: \.day) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(dayLabel(group.day))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.appMuted)
                                        .textCase(.uppercase)
                                    ForEach(group.items) { entry in
                                        NavigationLink {
                                            JournalDetailView(entry: entry)
                                        } label: {
                                            JournalRow(entry: entry)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNew = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New journal entry")
                }
            }
            .sheet(isPresented: $showNew) {
                NavigationStack { JournalFormView() }
            }
        }
    }

    private var groupedByDay: [(day: Date, items: [JournalEntry])] {
        let groups = Dictionary(grouping: entries) {
            Calendar.current.startOfDay(for: $0.createdAt)
        }
        return groups.keys.sorted(by: >).map { day in
            (day, (groups[day] ?? []).sorted { $0.createdAt > $1.createdAt })
        }
    }

    private func dayLabel(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Row

struct JournalRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.title.isEmpty ? "Quick note" : entry.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(entry.title.isEmpty ? Color.appMuted : Color.appInk)
                    .lineLimit(1)
                Spacer()
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.appMuted)
            }
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.subheadline)
                    .foregroundStyle(entry.title.isEmpty ? Color.appInk : Color.appMuted)
                    .lineLimit(3)
            }
            if !entry.photos.isEmpty || entry.audio != nil {
                HStack(spacing: 12) {
                    if !entry.photos.isEmpty {
                        Label("\(entry.photos.count)", systemImage: "photo")
                    }
                    if entry.audio != nil {
                        Label("Voice note", systemImage: "waveform")
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appAccent)
            }
        }
        .card(padding: 16)
    }
}

// MARK: - Detail

struct JournalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry

    @StateObject private var player = AudioPlayer()
    @State private var confirmDelete = false
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)

                if !entry.title.isEmpty {
                    Text(entry.title)
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .foregroundStyle(Color.appInk)
                }

                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(Color.appInk)
                }

                ForEach(Array(entry.photos.enumerated()), id: \.offset) { _, data in
                    if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }

                if let audio = entry.audio {
                    Button {
                        player.toggle(data: audio)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: player.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(Color.appAccent)
                            Text(player.isPlaying ? "Playing…" : "Play voice note")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.appInk)
                            Spacer()
                            Image(systemName: "waveform")
                                .foregroundStyle(Color.appMuted)
                        }
                        .card(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Edit entry")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete entry")
            }
        }
        .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete entry", role: .destructive) {
                context.delete(entry)
                dismiss()
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                JournalFormView(entry: entry)
            }
        }
    }
}

// MARK: - New / edit entry form

struct JournalFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// When set, the form edits this entry instead of creating a new one.
    private let entry: JournalEntry?

    @StateObject private var recorder = AudioRecorder()
    @StateObject private var player = AudioPlayer()

    @State private var title: String
    @State private var text: String
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var photos: [Data]
    @State private var audio: Data?

    init(entry: JournalEntry? = nil) {
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _text = State(initialValue: entry?.text ?? "")
        _photos = State(initialValue: entry?.photos ?? [])
        _audio = State(initialValue: entry?.audio)
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextField("What's on your mind?", text: $text, axis: .vertical)
                    .lineLimit(6...12)
            }

            Section("Photos") {
                PhotosPicker(selection: $pickedItems, maxSelectionCount: 4, matching: .images) {
                    Label(
                        photos.isEmpty ? "Add photos" : "Photos added (\(photos.count)) — tap to change",
                        systemImage: "photo.on.rectangle.angled"
                    )
                }
                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                                if let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                }
            }

            Section("Voice note") {
                if audio != nil {
                    HStack {
                        Button {
                            if let audio { player.toggle(data: audio) }
                        } label: {
                            Label(
                                player.isPlaying ? "Playing…" : "Play recording",
                                systemImage: player.isPlaying ? "stop.circle.fill" : "play.circle.fill"
                            )
                        }
                        Spacer()
                        Button("Remove", role: .destructive) { audio = nil }
                    }
                } else {
                    Button(action: toggleRecording) {
                        HStack(spacing: 10) {
                            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundStyle(recorder.isRecording ? Color.red : Color.appAccent)
                            Text(recorder.isRecording
                                 ? "Recording \(formattedDuration(recorder.elapsed)) — tap to stop"
                                 : "Record a voice note")
                        }
                    }
                    if recorder.permissionDenied {
                        Text("Microphone access is off. Enable it in Settings → Privacy & Security → Microphone.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(entry == nil ? "New entry" : "Edit entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if recorder.isRecording { recorder.stop() }
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .onChange(of: pickedItems) { _, items in
            Task {
                var loaded: [Data] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loaded.append(data)
                    }
                }
                photos = loaded
            }
        }
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !photos.isEmpty
            || audio != nil
    }

    private func toggleRecording() {
        if recorder.isRecording {
            audio = recorder.stop()
        } else {
            Task { await recorder.start() }
        }
    }

    private func save() {
        if recorder.isRecording {
            audio = recorder.stop()
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let entry {
            entry.title = trimmedTitle
            entry.text = trimmedText
            entry.photos = photos
            entry.audio = audio
        } else {
            context.insert(JournalEntry(
                title: trimmedTitle,
                text: trimmedText,
                photos: photos,
                audio: audio
            ))
        }
        dismiss()
    }
}
