from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_artifact_visibility import GameArtifactVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_artifact_data_type_0 import GameArtifactDataType0
    from ..models.game_artifact_summary_type_0 import GameArtifactSummaryType0


T = TypeVar("T", bound="GameArtifact")


@_attrs_define
class GameArtifact:
    """
    Attributes:
        id (str):
        game_id (str):
        kind (str):
        role (None | str):
        origin (str):
        visibility (GameArtifactVisibility):
        status (str):
        created_at (str):
        updated_at (str):
        slot (None | str | Unset):
        data (GameArtifactDataType0 | None | Unset):
        text (None | str | Unset):
        content_format (None | str | Unset):
        engine_version (None | str | Unset):
        summary (GameArtifactSummaryType0 | None | Unset):
        exposure_count (int | Unset):
        score (int | Unset):
        published_at (None | str | Unset):
        last_active_at (None | str | Unset):
    """

    id: str
    game_id: str
    kind: str
    role: None | str
    origin: str
    visibility: GameArtifactVisibility
    status: str
    created_at: str
    updated_at: str
    slot: None | str | Unset = UNSET
    data: GameArtifactDataType0 | None | Unset = UNSET
    text: None | str | Unset = UNSET
    content_format: None | str | Unset = UNSET
    engine_version: None | str | Unset = UNSET
    summary: GameArtifactSummaryType0 | None | Unset = UNSET
    exposure_count: int | Unset = UNSET
    score: int | Unset = UNSET
    published_at: None | str | Unset = UNSET
    last_active_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_artifact_data_type_0 import GameArtifactDataType0
        from ..models.game_artifact_summary_type_0 import GameArtifactSummaryType0

        id = self.id

        game_id = self.game_id

        kind = self.kind

        role: None | str
        role = self.role

        origin = self.origin

        visibility = self.visibility.value

        status = self.status

        created_at = self.created_at

        updated_at = self.updated_at

        slot: None | str | Unset
        if isinstance(self.slot, Unset):
            slot = UNSET
        else:
            slot = self.slot

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameArtifactDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        text: None | str | Unset
        if isinstance(self.text, Unset):
            text = UNSET
        else:
            text = self.text

        content_format: None | str | Unset
        if isinstance(self.content_format, Unset):
            content_format = UNSET
        else:
            content_format = self.content_format

        engine_version: None | str | Unset
        if isinstance(self.engine_version, Unset):
            engine_version = UNSET
        else:
            engine_version = self.engine_version

        summary: dict[str, Any] | None | Unset
        if isinstance(self.summary, Unset):
            summary = UNSET
        elif isinstance(self.summary, GameArtifactSummaryType0):
            summary = self.summary.to_dict()
        else:
            summary = self.summary

        exposure_count = self.exposure_count

        score = self.score

        published_at: None | str | Unset
        if isinstance(self.published_at, Unset):
            published_at = UNSET
        else:
            published_at = self.published_at

        last_active_at: None | str | Unset
        if isinstance(self.last_active_at, Unset):
            last_active_at = UNSET
        else:
            last_active_at = self.last_active_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "gameId": game_id,
                "kind": kind,
                "role": role,
                "origin": origin,
                "visibility": visibility,
                "status": status,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if slot is not UNSET:
            field_dict["slot"] = slot
        if data is not UNSET:
            field_dict["data"] = data
        if text is not UNSET:
            field_dict["text"] = text
        if content_format is not UNSET:
            field_dict["contentFormat"] = content_format
        if engine_version is not UNSET:
            field_dict["engineVersion"] = engine_version
        if summary is not UNSET:
            field_dict["summary"] = summary
        if exposure_count is not UNSET:
            field_dict["exposureCount"] = exposure_count
        if score is not UNSET:
            field_dict["score"] = score
        if published_at is not UNSET:
            field_dict["publishedAt"] = published_at
        if last_active_at is not UNSET:
            field_dict["lastActiveAt"] = last_active_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_artifact_data_type_0 import GameArtifactDataType0
        from ..models.game_artifact_summary_type_0 import GameArtifactSummaryType0

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("gameId")

        kind = d.pop("kind")

        def _parse_role(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        role = _parse_role(d.pop("role"))

        origin = d.pop("origin")

        visibility = GameArtifactVisibility(d.pop("visibility"))

        status = d.pop("status")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_slot(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        slot = _parse_slot(d.pop("slot", UNSET))

        def _parse_data(data: object) -> GameArtifactDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameArtifactDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameArtifactDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        def _parse_text(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        text = _parse_text(d.pop("text", UNSET))

        def _parse_content_format(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        content_format = _parse_content_format(d.pop("contentFormat", UNSET))

        def _parse_engine_version(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        engine_version = _parse_engine_version(d.pop("engineVersion", UNSET))

        def _parse_summary(data: object) -> GameArtifactSummaryType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                summary_type_0 = GameArtifactSummaryType0.from_dict(data)

                return summary_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameArtifactSummaryType0 | None | Unset, data)

        summary = _parse_summary(d.pop("summary", UNSET))

        exposure_count = d.pop("exposureCount", UNSET)

        score = d.pop("score", UNSET)

        def _parse_published_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        published_at = _parse_published_at(d.pop("publishedAt", UNSET))

        def _parse_last_active_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_active_at = _parse_last_active_at(d.pop("lastActiveAt", UNSET))

        game_artifact = cls(
            id=id,
            game_id=game_id,
            kind=kind,
            role=role,
            origin=origin,
            visibility=visibility,
            status=status,
            created_at=created_at,
            updated_at=updated_at,
            slot=slot,
            data=data,
            text=text,
            content_format=content_format,
            engine_version=engine_version,
            summary=summary,
            exposure_count=exposure_count,
            score=score,
            published_at=published_at,
            last_active_at=last_active_at,
        )

        game_artifact.additional_properties = d
        return game_artifact

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
