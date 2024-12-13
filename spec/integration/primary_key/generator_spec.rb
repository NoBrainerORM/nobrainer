require 'spec_helper'

describe "NoBrainer ID generator" do
  let(:subject) { NoBrainer::Document::PrimaryKey::Generator }

  it ".generate" do
    expect(subject.generate.length).to eq(subject::ID_STR_LENGTH)
  end

  it ".packed_to_alphanum" do
    expect(subject.packed_to_alphanum( 0)).to eq '00000000000000'
    expect(subject.packed_to_alphanum(61)).to eq '0000000000000z'
    expect(subject.packed_to_alphanum(62)).to eq '00000000000010'
    expect(subject.packed_to_alphanum(0x2930c8141d56c29ba5592)).to eq 'FYfIV9ideVIhRy'
  end

  it ".alphanum_to_packed" do
    expect(subject.alphanum_to_packed('00000000000000')).to eq 0
    expect(subject.alphanum_to_packed('0000000000000z')).to eq 61
    expect(subject.alphanum_to_packed('00000000000010')).to eq 62
    expect(subject.alphanum_to_packed('FYfIV9ideVIhRy')).to eq 0x2930c8141d56c29ba5592
  end

  it ".pack" do
    expect(subject.pack(
      time: Time.utc(2024,12,13, 4,56,42),
      sequence: 938,
      machine_id: 14177140,
      pid: 21906,
    )).to eq 0x2930c8141d56c29ba5592
  end

  it ".unpack" do
    expect(subject.unpack(0x2930c8141d56c29ba5592)).to match(
      time: Time.utc(2024,12,13, 4,56,42),
      sequence: 938,
      machine_id: 14177140,
      pid: 21906,
    )
  end
end
